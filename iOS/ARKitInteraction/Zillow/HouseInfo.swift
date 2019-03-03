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
    let zillowHomeValueIndex: String // localRealEstate][region][zindexValue, not a number. Has comma seperator
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
    
    /// The year in which the property was constructed.
    let yearBuilt: Int // yearBuilt
    
    /// The size of the lot in sq. ft.
    let lotSize: Int // lotSizeSqFt
    /// The size of the finished property in sq. ft.
    let propertySize: Int // finishedSqFt
    
    /// Number of bathrooms in the property.
    let bathroomsCount: Double // bathrooms
    /// Number of bedrooms in the property.
    let bedroomsCount: Int // bedrooms
    
    /// The year of the most recent tax assessment
    let taxAssessmentYear: Int // taxAssessmentYear
    /// The most recent tax assessment
    let taxAssessment: Double // taxAssessment
    
    /// The date of last sale for this property.
    let lastSoldDate: String // lastSoldDate, MM/dd/yyyy
    /// The price of the last sale for this property.
    let lastSoldPrice: Int // lastSoldPrice
}

extension HouseInfo {
    public static func ofHouse(at street: String, in cityState: String,
                               then process: @escaping (HouseInfo?) -> Void) {
        func errored(_ reason: String) { debugPrint(reason);process(nil)  }
        
        let urlString = "https://www.zillow.com/webservice/GetDeepSearchResults.htm?zws-id=X1-ZWz1gxswfm3m6j_4lr3d&address=\(street)&citystatezip=\(cityState)"
            .replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: urlString) else { return errored("Not valid url") }
        URLSession.shared.dataTask(with: url) { data,_,err in
            guard let data = data else { return errored(err?.localizedDescription ?? "Failed to fetch data from Zillow") }
            let xml = SWXMLHash.parse(data)
            let result = xml["SearchResults:searchresults"]["response"]["results"]["result"][0]
            do {
                process(HouseInfo(zestimate: .init(amount: try result["zestimate"]["amount"].value(),
                                                   lastUpdated: try result["zestimate"]["last-updated"].value(),
                                                   amountChangeInPast30Days: try result["zestimate"]["valueChange"].value(),
                                                   valuationRange: Range<Int>(uncheckedBounds:
                                                    (lower: try result["zestimate"]["valuationRange"]["low"].value(),
                                                     upper: try result["zestimate"]["valuationRange"]["high"].value()))),
                               zillowHomeValueIndex: try result["localRealEstate"]["region"]["zindexValue"].value(),
                               use: HouseInfo.Usecode(rawValue: try result["useCode"].value()) ?? .Unknown,
                               yearBuilt: try result["yearBuilt"].value(),
                               lotSize: try result["lotSizeSqFt"].value(),
                               propertySize: try result["finishedSqFt"].value(),
                               bathroomsCount: try result["bathrooms"].value(),
                               bedroomsCount: try result["bedrooms"].value(),
                               taxAssessmentYear: try result["taxAssessmentYear"].value(),
                               taxAssessment: try result["taxAssessment"].value(),
                               lastSoldDate: try result["lastSoldDate"].value(),
                               lastSoldPrice: try result["lastSoldPrice"].value()))
            } catch {
                return errored(error.localizedDescription)
            }
            }.resume()
    }
}
