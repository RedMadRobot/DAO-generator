//
//  Property+Parser.swift
//  DaoGenerator
//
//  Created by Andrei Rozhkov on 14/06/16.
//  Copyright © 2016 Redmadrobot. All rights reserved.
//

import Foundation


extension Property {

    func realm() -> Bool {
        var realm: Bool = false
        
        self.annotations.forEach { (a: Annotation) in
            if a.name == "realm" {
                realm = true
            }
        }
        
        return realm
    }
    
}
