//
//  SecretCodeVC.swift
//  BLE-Swift
//
//  Created by Kevin Chen on 2020/1/7.
//  Copyright © 2020 ss. All rights reserved.
//

import UIKit

extension String {

    func sliceInToVersion(from: String, to: String) -> String? {

        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, options: String.CompareOptions.backwards, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

class SecretCodeVC: BaseViewController {
    
    var otaExecuter:FactoryOTAExecuter? = nil
    
    var otaInfoConfig:BmobFactoryOTAInfoModel? = nil
    
    @IBOutlet weak var nextStepButton: UIButton!
    @IBOutlet weak var otaSuitInfoTextView: UITextView!
    @IBOutlet weak var secretCodeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "选择升级套装"
        nextStepButton.isHidden = true
        nextStepButton.layer.borderWidth = 1
        nextStepButton.layer.cornerRadius = 8
        nextStepButton.clipsToBounds = true
        nextStepButton.layer.borderColor = nextStepButton.tintColor.cgColor
        
        // Do any additional setup after loading the view.
        Bmob.register(withAppKey: "5cde76787542587a7ce90b2b54ef1f97")
        self.setNavRightButton(text: "手动校验", sel: #selector(navRightButtonAction))
        secretCodeTextField.text = "SlimTesH"

    }
    
    @objc func navRightButtonAction() {
        queryOTAInfo()
    }
    
    @IBAction func nextButtonAction(_ sender: UIButton) {
//        let otaInfoConfig = results![0]
        
        if (otaInfoConfig == nil) {
            return
        }
        
        self.startLoading(nil)
        let ftpPath = otaInfoConfig!.fileFTPPath
        let localPath = StorageUtils.getTempPath().stringByAppending(pathComponent: ftpPath!.lastPathComponent)
        
//        let ftpHelper = FTPHelper.shared
        
        let suffix1 = ".zip"
        let suffix2 = ".ZIP"
        let suffix3 = ".RAR"
        let suffix4 = ".rar"
        if (ftpPath!.hasSuffix(suffix1) ||
            ftpPath!.hasSuffix(suffix2) ||
            ftpPath!.hasSuffix(suffix3) ||
            ftpPath!.hasSuffix(suffix4) ) {
            
            self.downloadAction(localPath: localPath, ftpPath: ftpPath, progress: { (pro) in
                print(pro.fractionCompleted)
                self.showProgress(progress: Float(pro.fractionCompleted), status: "正在下载固件" + pro.localizedDescription);
            }) { (success, error) in
                self.stopLoading()
                if success {
                    self.unZipAction(localPath: localPath, ftpPath: ftpPath, progress: { (unZipProgress) in
                        self.showProgress(progress: Float(unZipProgress.fractionCompleted), status: "正在解压固件" + unZipProgress.localizedDescription);

                    }) { (unzipSuccess, unzipErr) in
                        self.stopLoading()
                        if unzipSuccess {
                            
                        }
                        else {
                            self.showError(unzipErr?.localizedDescription)
                        }
                    }
                }
                else {
                    self.showError(error?.localizedDescription)
                }
            }
        }
        else {
            self.stopLoading()
            self.alert(msg: "该路径不符合规范，请联系余美来" ,confirmText:"知道了", confirmSel: nil, cancelText: nil, cancelSel: nil)
        }
        
    }
    
    @IBAction func textChanged(_ sender: UITextField) {
        
        nextStepButton.isHidden = true
        otaSuitInfoTextView.text = nil
        otaInfoConfig = nil
        if sender.text?.count == 8 {
            queryOTAInfo()
        }
        
    }
    
    private func pushIntoAutoOTAVC(firmwaresDirectory:String!) {
        let otaVC = ZdOtaDisplayVC()
        let config = self.createConfig(otaInfoModel: self.otaInfoConfig!, firmwaresPath: firmwaresDirectory)
        otaVC.config = config
        self.navigationController?.pushViewController(otaVC, animated: true)
    }
    
    
    private func unSubZipActionIfNeeded(localDirectory:String, destinationDirectory:String!, progress:UnzipFileProgress?, completion:UnzipFileCompletion?) -> Bool {
        var needed:Bool = false
        
        let files = StorageUtils.getFiles(atDirectory: localDirectory)
        if files != nil {
            for file in files! {
                
                let filePath = localDirectory.stringByAppending(pathComponent: file)
                
                if file.hasSuffix(".zip") || file.hasSuffix(".rar") {
                    let unzipUtil:UnzipFileUtils = UnzipFileUtils.init()
                    unzipUtil.asyncUnzipFile(zipFilePath: filePath, destinationDir: localDirectory, progress: progress) { (succcess, error) in
                        
                        if succcess {
                            _ = StorageUtils.moveItem(fromPath: localDirectory, toPath: destinationDirectory)
                            self.pushIntoAutoOTAVC(firmwaresDirectory: destinationDirectory)
                        }
                        
                        if completion != nil {
                            completion!(succcess ,error)
                        }
                        
                    }

                    needed = true
                    break
                }
                else {
                    
                }
            }
        }
        
        return needed
    }
    
    private func unZipAction(localPath:String, ftpPath:String!, progress:UnzipFileProgress?, completion:UnzipFileCompletion?) {
            self.stopLoading()
            let fileName = ftpPath!.lastPathComponent
                                            
            let zipFileTempPath = localPath
            let unzipDestinationDir = StorageUtils.getTempPath().stringByAppending(pathComponent: "otaUnZipFilePath")
            let destinationDirectory = StorageUtils.getCahcePath().stringByAppending(pathComponent: "otaFW")

            _ = StorageUtils.deleteFile(atPath: unzipDestinationDir)
            _ = StorageUtils.deleteFile(atPath: destinationDirectory)

            let suffix1 = ".zip"
            let suffix2 = ".ZIP"
            let suffix3 = ".RAR"
            let suffix4 = ".rar"
            
            if (zipFileTempPath.hasSuffix(suffix1) ||
                zipFileTempPath.hasSuffix(suffix2) ||
                zipFileTempPath.hasSuffix(suffix3) ||
                zipFileTempPath.hasSuffix(suffix4) ) {
                
                let unzipUtil:UnzipFileUtils = UnzipFileUtils.init()
                unzipUtil.asyncUnzipFile(zipFilePath: zipFileTempPath, destinationDir: unzipDestinationDir, progress: progress) { (unZipSuccess, unZipError) in
                    if unZipSuccess {
                        self.stopLoading()
                        
                        let endIndex =  fileName.index(fileName.startIndex, offsetBy: (fileName.count - 4))
                        let unZipComponent = String(fileName[..<endIndex])
                        
                        let fwUpdatingDir = unzipDestinationDir.stringByAppending(pathComponent: unZipComponent).stringByAppending(pathComponent: "Update")
                        
                        
                        let needUnzipSubFile = self.unSubZipActionIfNeeded(localDirectory: fwUpdatingDir, destinationDirectory: destinationDirectory, progress: progress, completion: completion)
                        
                        if needUnzipSubFile {
                            
                        }
                        else {
                            _ = StorageUtils.moveItem(fromPath: fwUpdatingDir, toPath: destinationDirectory)
                            self.pushIntoAutoOTAVC(firmwaresDirectory: destinationDirectory)

                        }
                        
                        if completion != nil {
                            completion!(unZipSuccess, nil)
                        }

                    }
                    else {
                        self.showTip("解压错误");
                    }
                }
            }
            // 如果不是压缩包，而是一个文件夹，则需要遍历这个文件夹下的Update这个子文件夹下的所有文件，这些文件都是固件包，然后下载
            else {
                let fwUpdatingDir = zipFileTempPath.stringByAppending(pathComponent: "Update")
                StorageUtils.moveItem(fromPath: fwUpdatingDir, toPath: destinationDirectory)
                print("移动完成")
                
                let otaVC = ZdOtaDisplayVC()
                let config = self.createConfig(otaInfoModel: self.otaInfoConfig!, firmwaresPath: destinationDirectory)
                otaVC.config = config
                self.navigationController?.pushViewController(otaVC, animated: true)

            }
    }
    
    private func downloadAction(localPath:String, ftpPath:String!
        , progress:FTPProgressCallBack?, callback:FTPDownloadCallBack?) {
        let ftpHelper = FTPHelper.shared

        ftpHelper.asynDownloadFile(localPath: localPath, ftpPath: ftpPath!, progress: progress, callback: callback)
    }
    
    private func queryOTAInfo() {
        // 查找
        self.startLoading("正在校验")
        secretCodeTextField.resignFirstResponder()
        BmobFactoryOTAHelper.queryOTAConfig(secretCode: secretCodeTextField.text!) { (results:Array<BmobFactoryOTAInfoModel>?, error:Error?) in
            
            self.stopLoading()
            
            if (results != nil) {
                if results!.count == 1 {
                    // 正常
    //                        let ftpPath = "ftp://172.16.0.5/研发专用/3.3plus/P03A/Testing/APP/2019/1.0.6(23)/P03A_AT1.0.6(23).txt"
                    
                    self.nextStepButton.isHidden = false
                    self.otaInfoConfig = results![0]
                    
                    let suitInfoString = "客户名:\(self.otaInfoConfig!.customerName!) \n产品名:\(self.otaInfoConfig!.productName!) \n序号:\(self.otaInfoConfig!.otaSerialNumber!) \n固件版本:\(self.otaInfoConfig!.firmwareVersion ?? "未填写")"
                    self.otaSuitInfoTextView.text = suitInfoString
                    
                }
                else if results!.count > 1 {
                    // 有多个结果
    //                        self.showTip("查出了多个结果，不知道选择哪一个。请联系配置员确认信息。")
                    self.alert(msg: "查出了多个结果，不知道选择哪一个。请联系配置员确认信息。",confirmText:"知道了", confirmSel: nil, cancelText: nil, cancelSel: nil)
                }
                else if results!.count == 0 {
                    // 没找到结果
                    self.alert(msg: "没有找到升级任务。",confirmText:"知道了", confirmSel: nil, cancelText: nil, cancelSel: nil)
                }
            }
            else {
                self.alert(msg: "没有找到升级任务。",confirmText:"知道了", confirmSel: nil, cancelText: nil, cancelSel: nil)

            }
        }
    }
    
    private func createConfig(otaInfoModel:BmobFactoryOTAInfoModel, firmwaresPath:String!) -> OtaConfig {
        
        var config = OtaConfig()
        config.deviceNamePrefix = otaInfoModel.bleNamePrefix
        
        config.otaBleName = otaInfoModel.otaName
        
        if otaInfoModel.otaNamePrefix != nil {
            config.prefix = otaInfoModel.otaNamePrefix!
        }
        
        config.needReset = otaInfoModel.needReset!
        
        config.targetDeviceType = otaInfoModel.deviceType
        
        if otaInfoModel.platform.lowercased().hasPrefix("apollo") {
            config.platform = .apollo
        }
        else if (otaInfoModel.platform.lowercased().hasPrefix("nordic")) {
            config.platform = .nordic
        }
        else if (otaInfoModel.platform.lowercased().hasPrefix("tlsr")) {
            config.platform = .tlsr
        }
        
        config.signalMin = Int(-70)
        config.upgradeCountMax = Int(1)
        
        let manager = FileManager.default
        let directoryEnumerator = manager.enumerator(atPath: firmwaresPath)
        let allFirmwares:Array<Any> = directoryEnumerator!.allObjects
        
        var picPathArr = Array< Firmware>.init()
        var touchPathArr = Array<Firmware>.init()
        var platformPathArr = Array<Firmware>.init()
        var otherPathArr = Array<Firmware>.init()

        for (index,fileName) in allFirmwares.enumerated() {
            print("index = \(index)")

            print("firmwarePath = \(fileName)")
            
//            if fileName is String {
//                let firmwareName = String(fileName as! String)
//                if !firmwareName.lastPathComponent.contains("Language") {
//                    continue
//                }
//            }
            
            if fileName is String {
                let firmwareName = String(fileName as! String)
                
                if (!firmwareName.hasSuffix(".dat")) && (!firmwareName.hasSuffix(".bin")) {
                    continue
                }
                
                let pathString = firmwaresPath.stringByAppending(pathComponent: fileName as! String)

                let fw = Firmware.init()
                                
                fw.id = index
                fw.path = pathString
                let type = Firmware.getOtaType(withFileName: firmwareName)
                fw.type = type
                
                if fw.type == OtaDataType.picture {
                    let versionCodeStr = firmwareName.sliceInToVersion(from: "_", to: ".")
                    
                    if versionCodeStr != nil && versionCodeStr!.count > 0 {
                        let versionCode = Double(versionCodeStr!)
                        
                        if versionCode != nil {
                            fw.versionCode = versionCode!
                        }
                        else {
                            fw.versionCode = Double(MAXFLOAT)
                        }
                    }
                    else {
                        fw.versionCode = Double(MAXFLOAT)
                    }
                    
                }
                
                switch type {
                case .platform:
                    platformPathArr.append(fw)
                case .picture:
                    picPathArr.append(fw)
                case .touchPanel:
                    touchPathArr.append(fw)
                default:
                    otherPathArr.append(fw)
                }
                
            }
        }
        config.firmwares = config.firmwares + picPathArr + touchPathArr + platformPathArr + otherPathArr
        
        return config
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
