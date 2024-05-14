//
//  Theme.swift
//  mactop
//
//  Created by Laptop on 29/4/2024.
//

import Foundation
import SwiftData

struct ColorSet : Codable{
    var red : Double
    var green : Double
    var blue : Double
}

@Model
class Theme {
    @Attribute(.unique) var name: String
    var primary : ColorSet
    var secondary : ColorSet
    var tertiary : ColorSet
    
    init(name : String) {
        self.name = name
        self.primary = ColorSet(red: 0.25, green: 0.61, blue: 1)
        self.secondary = ColorSet(red: 1, green: 1, blue: 1)
        self.tertiary = ColorSet(red: 0.21, green: 0.4, blue: 1)
    }
    
    init(name : String, primary: ColorSet, secondary: ColorSet, tertiary: ColorSet) {
        self.name = name
        self.primary = primary
        self.secondary = secondary
        self.tertiary = tertiary
    }
}
