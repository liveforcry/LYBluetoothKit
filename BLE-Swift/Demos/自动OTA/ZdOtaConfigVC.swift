//
//  ZdOtaConfigVC.swift
//  BLE-Swift
//
//  Created by SuJiang on 2019/1/19.
//  Copyright © 2019 ss. All rights reserved.
//

import UIKit
import DLRadioButton

class ZdOtaConfigVC: BaseViewController, PrefixSelectVCDelegate {

    @IBOutlet weak var bleNameTF: UITextField!
    
    @IBOutlet weak var prefixTF: UITextField!
    
    @IBOutlet weak var signalLbl: UILabel!
    
    @IBOutlet weak var signalSlider: UISlider!
    
    @IBOutlet weak var apolloRadio: DLRadioButton!
    
    @IBOutlet weak var nordicRadio: DLRadioButton!
    
    @IBOutlet weak var tlsrRadio: DLRadioButton!
    
    @IBOutlet weak var upgradeCountLbl: UILabel!
    
    @IBOutlet weak var upgradeCountSlider: UISlider!
    
    @IBOutlet weak var needResetSw: UISwitch!
    
    @IBOutlet weak var normalSpeedRadio: DLRadioButton!
    
    @IBOutlet weak var fastSpeedRadio: DLRadioButton!
    
    @IBOutlet weak var speedTF: UITextField!
    
    @IBOutlet weak var prefixSelectBtn: UIButton!
    
    @IBOutlet weak var customOTANameSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bleNameTF.leftViewMode = .always
        bleNameTF.rightViewMode = .always
        let lbl = UILabel(frame: CGRect(x: 0, y: 0, width: 110, height: bleNameTF.height))
        lbl.text = TR("  蓝牙名称前缀: ")
        lbl.textColor = kMainColor
        lbl.font = font(14)
        bleNameTF.leftView = lbl
        
        prefixTF.leftViewMode = .always
        prefixTF.rightViewMode = .always
        let lbl2 = UILabel(frame: CGRect(x: 0, y: 0, width: 110, height: bleNameTF.height))
        lbl2.text = TR("  OTA名称前缀: ")
        lbl2.textColor = kMainColor
        lbl2.font = font(14)
        prefixTF.leftView = lbl2
        
//        let selBtn = UIButton(type: .custom)
//        selBtn.frame = CGRect(x: 0, y: 0, width: 60, height: bleNameTF.height)
//        selBtn.backgroundColor = kMainColor
//        selBtn.setTitle(TR("选择"), for: .normal)
//        selBtn.addTarget(self, action: #selector(selBtnClick), for: .touchUpInside)
//        selBtn.titleLabel?.font = font(14)
//        bleNameTF.rightView = selBtn
//
//        let selBtn2 = UIButton(type: .custom)
//        selBtn2.frame = CGRect(x: 0, y: 0, width: 60, height: prefixTF.height)
//        selBtn2.backgroundColor = kMainColor
//        selBtn2.setTitle(TR("选择"), for: .normal)
//        selBtn2.addTarget(self, action: #selector(selBtnClick), for: .touchUpInside)
//        selBtn2.titleLabel?.font = font(14)
//        prefixTF.rightView = selBtn2
        

        apolloRadio.otherButtons = [nordicRadio, tlsrRadio]
        normalSpeedRadio.otherButtons = [fastSpeedRadio]
        
        if AppConfig.current.mtu == 20 {
            normalSpeedRadio.isSelected = true
        } else {
            fastSpeedRadio.isSelected = true
        }
        speedTF.text = "\(AppConfig.current.mtu)"
        
        setNavRightButton(text: TR("下一步"), sel: #selector(nextBtnClick))
        
        self.title = TR("自动升级配置")
    }


    // MARK: - 事件处理
    @objc func nextBtnClick() {
        
        guard let bleName = bleNameTF.text, bleName.count > 0 else {
            showError(TR("请输入蓝牙名称前缀"))
            return
        }
        
        let prefixStr = prefixTF.text
        if customOTANameSwitch.isOn {
            guard let prefix = prefixStr, prefix.count > 0 else {
                showError(TR("请输入自定OTA名称"))
                return
            }
        }
        else {
            guard let prefix = prefixStr, prefix.count > 0 else {
                showError(TR("请输入OTA名称前缀"))
                return
            }
        }
        
        
        guard let mtuStr = speedTF.text, mtuStr.count > 0 else {
            showError("请输入正确的MTU值，不能小于20，而且是2的倍数")
            return
        }
        
        AppConfig.current.mtu = Int(mtuStr) ?? 20
        AppConfig.current.save()
        
        var config = OtaConfig()
        config.deviceNamePrefix = bleName
        
        if customOTANameSwitch.isOn {
            config.otaBleName = prefixStr
        }
        else {
            config.prefix = prefixStr!
        }
        
        config.needReset = needResetSw.isOn
        
        if apolloRadio.isSelected {
            config.platform = .apollo
        } else if nordicRadio.isSelected {
            config.platform = .nordic
        } else if tlsrRadio.isSelected {
            config.platform = .tlsr
        }
        
        config.signalMin = Int(-signalSlider.value)
        config.upgradeCountMax = Int(upgradeCountSlider.value)
        
        let vc = ZdOtaFirmwaresVC()
        vc.config = config
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func signalChanged(_ sender: UISlider) {
        signalLbl.text = "最小信号强度: \(-Int(sender.value))"
    }
    
    @IBAction func upgradeCountChanged(_ sender: UISlider) {
        upgradeCountLbl.text = "\(Int(sender.value))台"
    }
    
    @IBAction func resetSwValueChanged(_ sender: UISwitch) {
        
    }
    
    
    @IBAction func selBtnClick() {
        let vc = PrefixSelectVC()
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func useCustomOTANameSwitchAction(_ sender: UISwitch) {
        let titleLabel:UILabel = prefixTF!.leftView as! UILabel
        
        if sender.isOn {
            titleLabel.text = "  自定OTA名称: "
        }
        else {
            titleLabel.text = "  OTA名称前缀: "
            
        }
    }
    
    @IBAction func normalSpeedValueChanged(_ sender: Any) {
        speedTF.text = "20"
    }
    
    @IBAction func fastSpeedValueChanged(_ sender: Any) {
        speedTF.text = "120"
    }
    
    @IBAction func normalSpeedBtnClick(_ sender: Any) {
        speedTF.text = "20"
    }
    
    @IBAction func fastSpeedBtnClick(_ sender: Any) {
        speedTF.text = "120"
    }
    
    
    
    // MARK: - 代理
    func didSelectPrefixStr(prefixStr: String, bleName: String) {
        bleNameTF.text = bleName
        prefixTF.text = prefixStr
    }
    
}
