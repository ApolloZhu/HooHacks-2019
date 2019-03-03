//
//  HouseInfo.swift
//  ARKitInteraction
//
//  Created by A on 3/3/19.
//  Copyright © 2019 <script>alert("Who Hacks?")</script>. All rights reserved.
//

import Foundation
import SWXMLHash

struct HouseInfo {
    let zestimate: Zestimate
    struct Zestimate {
        let amount: Int // amount
        let lastUpdated: String // last-updated, MM/dd/yyyy
        let amountChangeInPast30Days: Int // valueChange
        let valuationRange: Range<Int> // valuationRange][low or high
    }
    let zillowHomeValueIndex: Int // localRealEstate][region][zindexValue, not a number. Has comma seperator
    let use: Usecode
    enum Usecode: String {
        case Unknown
        case SingleFamily
        case Duplex
        case Triplex
        case Quadruplex
        case Condominium
        case Cooperative
        case Mobile
        case MultiFamily2To4
        case MultiFamily5Plus
        case Timeshare
        case Miscellaneous
        case VacantResidentialLand
    }
}

extension HouseInfo {
    struct Highlight {
        let price: Int
        let numOfBedroom: Int
        let numOfBathroom: Double
        let sqft: Int
    }
    
    public static func ofHouse(at street: String, in cityState: String,
                               then process: @escaping (HouseInfo.Highlight?) -> Void) {
        func errored(_ reason: String) { debugPrint(reason);process(nil)  }
        
        let urlString = "https://www.zillow.com/webservice/GetDeepSearchResults.htm?zws-id=X1-ZWz1gxswfm3m6j_4lr3d&address=\(street)&citystatezip=\(cityState)"
            .replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: urlString) else { return errored("Not valid url") }
        URLSession.shared.dataTask(with: url) { data,_,err in
            guard let data = data else { return errored(err?.localizedDescription ?? "Failed to fetch data from Zillow") }
            let xml = SWXMLHash.parse(data)
            let result = xml["SearchResults:searchresults"]["response"]["results"]["result"][0]
            do {
                process(HouseInfo.Highlight(
                    price: try result["zestimate"]["amount"].value(),
                    numOfBedroom: try result["bedrooms"].value(),
                    numOfBathroom: try result["bathrooms"].value(),
                    sqft: try result["finishedSqFt"].value()
                ))
            } catch {
                return errored(error.localizedDescription)
            }
        }.resume()
    }
}
