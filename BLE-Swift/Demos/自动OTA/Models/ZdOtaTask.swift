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

let kZdOtaTaskReady = Notification.Name("kZdOtaTaskReady")
// error: BLEError, task: ZdOtaTask
let kZdOtaTaskFailed = Notification.Name("kZdOtaTaskFailed")
let kZdOtaTaskSuccess = Notification.Name("kZdOtaTaskSuccess")
// progress: Float, task: ZdOtaTask
let kZdOtaTaskProgressUpdate = Notification.Name("kZdOtaTaskProgressUpdate")

let kZdOtaTaskMaxTryCount = 3

class ZdOtaTask: Equatable {
    
    var state: ZdOtaTaskState = .plain
    var error: BLEError?
    var progress: Float = 0
    
    var tryCount: Int = 0
    
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
        
        
        var otaBleName = config.prefix + device.name.suffix(5)
        if config.prefix.count == 0 || device.isApollo3 {
            otaBleName = device.name
        }
        
        var otaDatas = [OtaDataModel]()
        
        var nordicDatData:Data? = nil
        
        for fm in config.firmwares {
            
//            let path = StorageUtils.getDocPath().stringByAppending(pathComponent: fm.path)
            let path = fm.path
            
//            do {
//                var data = try Data(contentsOf: URL(fileURLWithPath: path))
//                let dm = OtaDataModel(type: fm.type, data: data)
//                otaDatas.append(dm)
//                data.removeAll()
//            }
//            catch {}
            
            let data = StorageUtils.getData(atPath: path)
            
            print(path)
            
            if (data != nil) {
                
                if path.hasSuffix(".dat") && config.platform == .nordic {
                    nordicDatData = data
                }
                else {
                    let dm = OtaDataModel(type: fm.type, data: data!)
                    otaDatas.append(dm)
                }
                
            }
        }
        
        if config.platform == .nordic && nordicDatData != nil {
            for otaData in otaDatas {
                otaData.datData = nordicDatData
            }
        }
        
        if device.isApollo3 {
//            BLEConfig.shared.mtu = 128;
            BLEConfig.shared.mtu = AppConfig.current.mtuForApollo3
        } else {
//            BLEConfig.shared.mtu = 20;
            BLEConfig.shared.mtu = AppConfig.current.mtu
        }
        
        weak var weakSelf = self
        
        let readyBlock = { NotificationCenter.default.post(name: kZdOtaTaskReady, object: nil, userInfo: nil) }
        
        let progressBlock = {(progress:Float) -> Void in
            weakSelf?.progressCallback?(progress)
            
            NotificationCenter.default.post(name: kZdOtaTaskProgressUpdate, object: nil, userInfo: ["progress": progress, "task": self])
        }
        
        let finishBlock = {(bool: Bool, error: BLEError?) in
            if error != nil {
                            weakSelf?.state = .fail
                            weakSelf?.error = error
                            weakSelf?.endTime = Date().timeIntervalSince1970
                            
                            weakSelf?.finishCallback?(bool, error)
                            
                            NotificationCenter.default.post(name: kZdOtaTaskFailed, object: nil, userInfo: ["error": error!, "task": self])
                        } else {
                            if let bool = weakSelf?.config.needReset, bool == true {
                                weakSelf?.startResetDevice()
                            } else {
                                weakSelf?.otaSuccess(isReset: false)
                            }
            //                if self.config.needReset {
            //                    self.startResetDevice()
            //                } else {
            //                    self.otaSuccess()
            //                }
                        }
        }
        
        
        switch config.platform {
        case .apollo:
            otaTask = OtaManager.shared.startOta(device: device, otaBleName: otaBleName, otaDatas: otaDatas, readyCallback: {
                readyBlock()
            }, progressCallback: { (progress) in
                progressBlock(progress)
            }, finishCallback: { (bool, error) in
                finishBlock(bool, error)
            })
        case .nordic:
            otaTask = OtaManager.shared.startNordicOta(device: device, otaBleName: otaBleName, otaDatas: otaDatas, readyCallback: {
                readyBlock()
            }, progressCallback: { (progress) in
                progressBlock(progress)
            }, finishCallback: { (bool, error) in
                finishBlock(bool, error)
            })
        case .tlsr:
            otaTask = OtaManager.shared.startTlsrOta(device: device, otaBleName: otaBleName, otaDatas: otaDatas, readyCallback: {
                readyBlock()
            }, progressCallback: { (progress) in
                progressBlock(progress)
            }, finishCallback: { (bool, error) in
                finishBlock(bool, error)
            })
        }
        
//        otaTask = OtaManager.shared.startOta(device: device, otaBleName: otaBleName, otaDatas: otaDatas, readyCallback: {
//            NotificationCenter.default.post(name: kZdOtaTaskReady, object: nil, userInfo: nil)
//        }, progressCallback: { (progress) in
//
//            weakSelf?.progressCallback?(progress)
//
//            NotificationCenter.default.post(name: kZdOtaTaskProgressUpdate, object: nil, userInfo: ["progress": progress, "task": self])
//        }, finishCallback: { (bool, error) in
//
//            if error != nil {
//                weakSelf?.state = .fail
//                weakSelf?.error = error
//                weakSelf?.endTime = Date().timeIntervalSince1970
//
//                weakSelf?.finishCallback?(bool, error)
//
//                NotificationCenter.default.post(name: kZdOtaTaskFailed, object: nil, userInfo: ["error": error!, "task": self])
//            } else {
//                if let bool = weakSelf?.config.needReset, bool == true {
//                    weakSelf?.startResetDevice()
//                } else {
//                    weakSelf?.otaSuccess(isReset: false)
//                }
////                if self.config.needReset {
////                    self.startResetDevice()
////                } else {
////                    self.otaSuccess()
////                }
//            }
//        })
        otaTask!.config = config
    }
    
    private var connectTimer: Timer?
    private var connectCount = 0
    private func startResetDevice() {
        print("ota(\(name))成功了，开始等待连接，并重置设备")
        
        var delay:Double = 20
        for fw in self.config.firmwares {
            if fw.type == .touchPanel {
                delay = 90
                break
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.connectDevice()
        }
    }
    
    private func connectDevice() {
        
        if connectCount > 6 {
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
            self.otaSuccess(isReset: true)
        }, toDeviceName: name)
    }
    
    private func otaSuccess(isReset: Bool) {
        self.state = .success
        self.endTime = Date().timeIntervalSince1970
        self.hadResetDevice = isReset
        self.finishCallback?(true, nil)
        NotificationCenter.default.post(name: kZdOtaTaskSuccess, object: nil, userInfo: ["task": self])
    }
    
    public static func == (lhs: ZdOtaTask, rhs: ZdOtaTask) -> Bool {
        return lhs.name == rhs.name
    }
    
}
