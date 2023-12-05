//
//  Model.swift
//  MapLocation
//
//  Created by Aniket Patil on 29/11/23.
//

import Foundation

struct APIData: Codable {
    let name: CountryName
    let flags: FlagsData
    let latlng: [Double]
    
    struct CountryName: Codable {
        let common: String
    }
    
    struct FlagsData: Codable {
        let png: String
    }
}
