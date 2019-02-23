//
//  AppDelegate.swift
//  BLE-Swift
//
//  Created by SuJiang on 2018/9/17.
//  Copyright © 2018年 ss. All rights reserved.
//

import UIKit

let kFirmwareFilePath = StorageUtils.getDocPath() + "/Firmwares"


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
    
        createFirmwareDirectory()
        
        SlideMenuOptions.leftViewWidth = UIScreen.main.bounds.width - 80;
        SlideMenuOptions.panGesturesEnabled = false
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let homeVC = HomeViewController()
        
        let slideVC = SlideMenuController(mainViewController: homeVC, leftMenuViewController: LeftViewController())

        window?.rootViewController = slideVC
        window?.makeKeyAndVisible()
        
//        BLEConfig.shared.shouldSend03End = false
        
        return true
    }
    
    // MARK: - 文件操作业务
    func createFirmwareDirectory() {
        if !StorageUtils.isFileExits(atPath: kFirmwareFilePath) {
            _ = StorageUtils.createPath(path: kFirmwareFilePath)
        }
    }
    
    
    

    // MARK: - 生命周期
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let fileName = url.absoluteString.lastPathComponent
        
        // 如果是协议导入
        if fileName.hasPrefix("ProtocolMenus") {
            let alert = UIAlertController(title: "非常重要", message: "是否要覆盖本地的协议配置信息？", preferredStyle: .alert)
            let ok = UIAlertAction(title: "确定", style: .default) { (letion) in
                let data = (try? Data(contentsOf: url)) ?? Data()
                _ = StorageUtils.save(data, forKey: ProtocolService.kMenusCacheKey)
                ProtocolService.shared.refreshMenusFromDisk()
            }
            let cancel = UIAlertAction(title: "取消", style: .cancel) { (action) in
                _ = StorageUtils.deleteFile(atPath: url.absoluteString)
            }
            alert.addAction(ok)
            alert.addAction(cancel)
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            return true
        }
        
        // 如果是工具导入
        if fileName.hasPrefix("DeviceProducts") {
            let alert = UIAlertController(title: "非常重要", message: "是否要覆盖本地的工具配置信息？", preferredStyle: .alert)
            let ok = UIAlertAction(title: "确定", style: .default) { (action) in
                
            }
            let cancel = UIAlertAction(title: "取消", style: .cancel) { (action) in
                _ = StorageUtils.deleteFile(atPath: url.absoluteString)
            }
            alert.addAction(ok)
            alert.addAction(cancel)
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            return true
        }
        
        let filePath = "Inbox".stringByAppending(pathComponent: fileName)
        
        let absolutePath = StorageUtils.getDocPath().stringByAppending(pathComponent: filePath)
        
        if !StorageUtils.isFileExits(atPath: absolutePath) {
            return false
        }
        
        let fm = Firmware()
        fm.name = fileName
        fm.path = filePath
        fm.id = Int(Date().timeIntervalSince1970)
        
        let vc = FirmwareSaveVC()
        vc.tmpFirmware = fm
        
        let nav = LYNavigationController(rootViewController: vc)
        self.window?.rootViewController?.present(nav, animated: true, completion: nil)
        
        return true
    }

}

