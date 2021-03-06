//
//  LeftDeviceCell.swift
//  BLE-Swift
//
//  Created by SuJiang on 2019/1/3.
//  Copyright © 2019 ss. All rights reserved.
//

import UIKit

protocol LeftDeviceCellDelegate: NSObjectProtocol {
    func didClickEditBtn(cell: UITableViewCell)
}


class LeftDeviceCell: UITableViewCell {

    @IBOutlet weak var signalView: SignalStrengthView!
    
    @IBOutlet weak var nameLbl: UILabel!
    
    @IBOutlet weak var serviceLbl: UILabel!
    
    @IBOutlet weak var dot: UIView!
    
    @IBOutlet weak var debugBtn: UIButton!
    
    weak var delegate: LeftDeviceCellDelegate?
    
    var device: BLEDevice? {
        didSet {
            updateUI(withDevice: device)
        }
    }
    
    func updateUI(withDevice device: BLEDevice?) {
        if device == nil {
            signalView.strength = -100
            nameLbl.text = ""
            serviceLbl.text = ""
        } else {
            signalView.strength = device!.rssi ?? -100
            nameLbl.text = device!.name
            serviceLbl.text = device!.broadcastServiceUUIDs.count > 0 ? "[\(device!.broadcastServiceUUIDs.count) services]" : "No services"
            dot.isHidden = (device!.state == .disconnected)
        }
    }
    
    func setDebugHidden(hidden: Bool) {
        debugBtn.isHidden = hidden
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dot.layer.cornerRadius = dot.bounds.width / 2
        dot.layer.masksToBounds = true
    }

    @IBAction func editBtnClick(_ sender: Any) {
        delegate?.didClickEditBtn(cell: self)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
