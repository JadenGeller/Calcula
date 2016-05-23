//
//  Binding.swift
//  Calcula
//
//  Created by Jaden Geller on 5/22/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

public final class Binding {
    public required init() {
        
    }
}

extension Binding: CustomStringConvertible {
    public var description: String {
        return "{" + String(ObjectIdentifier(self).uintValue) + "}"
    }
}

extension Binding: Hashable {
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}

extension Binding: Equatable { }
public func ==(lhs: Binding, rhs: Binding) -> Bool {
    return lhs === rhs
}

extension Binding {
    /// Returns `true` iff `self` is not bound to any lambda argument within the term.
    public func isFresh<Variable: VariableType>(in term: Term<Variable>) -> Bool {
        return !term.freeVariables.contains(self)
    }
}
