//
//  Utils.swift
//  GeoARDJ
//
//  Created by Mac on 7/28/17.
//  Copyright © 2017 Mac. All rights reserved.
//

import Foundation

extension String {
    func index(of target: String) -> Int? {
        if let range = self.range(of: target) {
            return characters.distance(from: startIndex, to: range.lowerBound)
        } else {
            return nil
        }
    }
    
    func lastIndex(of target: String) -> Int? {
        if let range = self.range(of: target, options: .backwards) {
            return characters.distance(from: startIndex, to: range.lowerBound)
        } else {
            return nil
        }
    }
    
    func lastIndex(of target: String) -> String.Index? {
        return self.range(of: target, options: .backwards)?.lowerBound
    }
    
}
