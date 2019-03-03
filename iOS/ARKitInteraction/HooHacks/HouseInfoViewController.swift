//
//  HouseInfoViewController.swift
//  ARKitInteraction
//
//  Created by Apollo Zhu on 3/3/19.
//  Copyright © 2019 <script>alert("Who Hacks?")</script>. All rights reserved.
//

import UIKit
import FloatingPanel

class HouseInfoViewController: UITableViewController {
    @IBOutlet weak var streetNameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var bedroomCountLabel: UILabel!
    @IBOutlet weak var bathroomCountLabel: UILabel!
}

extension ViewController: FloatingPanelControllerDelegate {
    
}
