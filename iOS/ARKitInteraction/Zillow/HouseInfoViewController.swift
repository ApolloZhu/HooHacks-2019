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
    @IBOutlet private weak var streetNameLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var areaLabel: UILabel!
    @IBOutlet private weak var bedroomCountLabel: UILabel!
    @IBOutlet private weak var bathroomCountLabel: UILabel!
    @IBOutlet private weak var typeLabel: UILabel!
    @IBOutlet private weak var yearBuiltLabel: UILabel!
    @IBOutlet private weak var zIndexLabel: UILabel!
    
    @IBOutlet var toHide: [UIView]!
    
    func setHouse(_ house: HouseInfo?, at street: String) {
        streetNameLabel.text = street
        guard let house = house else {
            priceLabel.text = "No Information Available"
            for view in toHide { view.isHidden = true }
            return
        }
        for view in toHide { view.isHidden = false }
        priceLabel.text = "$ \(house.zestimate.amount)"
        areaLabel.text = "\(house.propertySize) ft²"
        bathroomCountLabel.text = "\(house.bathroomsCount)"
        bedroomCountLabel.text = "\(house.bedroomsCount)"
        typeLabel.text = house.use.rawValue
        yearBuiltLabel.text = "\(house.yearBuilt)"
        zIndexLabel.text = house.zillowHomeValueIndex
    }
}

extension ViewController: FloatingPanelControllerDelegate { }
