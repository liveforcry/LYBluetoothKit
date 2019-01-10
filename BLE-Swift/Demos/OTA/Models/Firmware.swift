//
//  Firmware.swift
//  BLE-Swift
//
//  Created by SuJiang on 2019/1/8.
//  Copyright © 2019 ss. All rights reserved.
//

import UIKit

struct Firmware: Codable {
    var id = 0
    var name = "" {
        didSet {
            type = Firmware.getOtaType(withFileName: name)
        }
    }
    var path = ""
    var versionName = ""
    var versionCode = 0
    var type: OtaDataType = .platform
    var createTime: TimeInterval = Date().timeIntervalSince1970
    
    static func getOtaType(withFileName fileName: String) -> OtaDataType{
        let tmp = fileName.lowercased()
        if tmp.hasPrefix("apollo") {
            return .platform
        }
        else if tmp.hasPrefix("appollo") {
            return .platform
        }
        else if tmp.hasPrefix("appllo") {
            return .platform
        }
        else if tmp.hasPrefix("apollo3") {
            return .platform
        }
        else if tmp.hasPrefix("application") {
            return .platform
        }
        else if tmp.hasPrefix("heartrate") {
            return .platform
        }
        else if tmp.hasPrefix("picture") {
            return .platform
        }
        else if tmp.hasPrefix("touchpanel") {
            return .platform
        }
        else {
            return .platform
        }
    }
    
    static func getTypeName(withType type: OtaDataType) -> String {
        switch type {
        case .platform:
            return TR("固件")
        case .picture:
            return TR("字库")
        case .heartRate:
            return TR("心率")
        case .touchPanel:
            return TR("触摸")
        default:
            return TR("未知")
        }
    }
    
}