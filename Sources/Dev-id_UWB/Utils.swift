//
//  Utils.swift
//  
//
//  Created by Nathan Zerbib on 17/06/2022.
//

import Foundation

extension Dictionary {
    func appending(_ key: Key, _ value: Value) -> [Key: Value] {
        var result = self
        result[key] = value
        return result
    }
}
