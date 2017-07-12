//
//  Klass+Translator.swift
//  ParserGenerator
//
//  Created by Egor Taflanidi on 14.06.28.
//  Copyright © 28 Heisei RedMadRobot LLC. All rights reserved.
//

import Foundation


extension Klass {
    
    var isModel: Bool {
        return annotations.contains(Annotation(name: "model", value: nil))
    }
    
}
