//
//  ZdOtaTask.swift
//  BLE-Swift
//
//  Created by SuJiang on 2019/1/21.
//  Copyright © 2019 ss. All rights reserved.
//

import UIKit

enum ZdOtaTaskState: Int {
    case plain = 0
    case start
    case waitVerify
    case success
    case fail
}

// error: BLEError, task: ZdOtaTask
let kZdOtaTaskFailed = Notification.Name("kZdOtaTaskFailed")
let kZdOtaTaskSuccess = Notification.Name("kZdOtaTaskSuccess")
// progress: Float, task: ZdOtaTask
let kZdOtaTaskProgressUpdate = Notification.Name("kZdOtaTaskProgressUpdate")

class ZdOtaTask: Equatable {
    
    var state: ZdOtaTaskState = .plain
    var error: BLEError?
    var progress: Float = 0
    
    var name: String
    
    var config: OtaConfig
    
    var device: BLEDevice!
    
    var progressCallback: FloatCallback?
    var finishCallback: BoolCallback?
    
    private var otaTask: OtaTask?
    
    init(name: String, config: OtaConfig) {
        self.name = name
        self.config = config
        
        startTime = Date().timeIntervalSince1970
    }
    
    var startTime: TimeInterval = 0
    var endTime: TimeInterval = 0
    var hadResetDevice: Bool = false
    
    func startOTA(withDevice device: BLEDevice) {
        
        self.device = device
        state = .start
        
        
        var otaBleName = config.prefix + config.deviceName.suffix(5)
        if config.prefix.count == 0 || device.isApollo3 {
            otaBleName = device.name
        }
        
        var otaDatas = [OtaDataModel]()
        for fm in config.firmwares {
            
            let path = StorageUtils.getDocPath().stringByAppending(pathComponent: fm.path)
            
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let dm = OtaDataModel(type: fm.type, data: data)
                otaDatas.append(dm)
            }
            catch {}
        }
        
        if device.isApollo3 {
            BLEConfig.shared.mtu = 128;
        } else {
            BLEConfig.shared.mtu = 20;
        }
        
        weak var weakSelf = self
        otaTask = OtaManager.shared.startOta(device: device, otaBleName: otaBleName, otaDatas: otaDatas, readyCallback: {
            
        }, progressCallback: { (progress) in
            
            weakSelf?.progressCallback?(progress)
            
            NotificationCenter.default.post(name: kZdOtaTaskProgressUpdate, object: nil, userInfo: ["progress": progress, "task": self])
        }, finishCallback: { (bool, error) in
            
            if error != nil {
                weakSelf?.state = .fail
                weakSelf?.error = error
                weakSelf?.endTime = Date().timeIntervalSince1970
                
                weakSelf?.finishCallback?(bool, error)
                
                NotificationCenter.default.post(name: kZdOtaTaskFailed, object: nil, userInfo: ["error": error!, "task": self])
            } else {
                weakSelf?.startResetDevice()
            }
        })
        otaTask!.config = config
    }
    
    private var connectTimer: Timer?
    private var connectCount = 0
    private func startResetDevice() {
        print("ota(\(name))成功了，开始等待连接，并重置设备")
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            self.connectDevice()
        }
    }
    
    private func connectDevice() {
        
        if connectCount > 8 {
            state = .success
            self.endTime = Date().timeIntervalSince1970
            self.finishCallback?(true, nil)
            NotificationCenter.default.post(name: kZdOtaTaskSuccess, object: nil, userInfo: ["task": self])
            return
        }
        
        weak var weakSelf = self
        BLECenter.shared.connect(deviceName: name, callback: { (d, err) in
            if err != nil || d == nil {
                weakSelf?.connectCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                    weakSelf?.connectDevice()
                })
            } else {
                weakSelf?.resetDevice()
            }
        }, timeout: 5)
    }
    
    private func resetDevice() {
        print("连接设备(\(name))成功，开始重置设备")
        _ = BLECenter.shared.resetDevice(boolCallback: { (bool, error) in
            self.state = .success
            self.endTime = Date().timeIntervalSince1970
            self.hadResetDevice = true
            self.finishCallback?(true, nil)
            NotificationCenter.default.post(name: kZdOtaTaskSuccess, object: nil, userInfo: ["task": self])
        }, toDeviceName: name)
    }
    
    
    public static func == (lhs: ZdOtaTask, rhs: ZdOtaTask) -> Bool {
        return lhs.name == rhs.name
    }
    
}
