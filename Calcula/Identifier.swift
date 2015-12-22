//
//  Identifier.swift
//  Calcula
//
//  Created by Jaden Geller on 12/21/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

class Identifier {
    init() {}
}

extension Identifier: Hashable {
    var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}
func ==(lhs: Identifier, rhs: Identifier) -> Bool {
    return lhs === rhs
}

class Data: Identifier {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
}