//
//  Variable.swift
//  Calcula
//
//  Created by Jaden Geller on 5/22/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

public protocol VariableType {
    init(_ binding: Binding)
    var boundBinding: Binding? { get }
}

// A variable such that only lambda terms are used.
public struct PureVariable {
    // Identifier representation of variable bound to separate usage.
    public var binding: Binding
    
    public init(_ binding: Binding) {
        self.binding = binding
    }
}

extension PureVariable: VariableType {
    public var boundBinding: Binding? {
        return binding
    }
}

// A variable such that constants may be represented.
public enum ImpureVariable {
    // Identifier representation of variable bound to separate usage.
    case binding(Binding)
    
    // Constained constant.
    case constant(Any)
}

extension ImpureVariable {
    public init(_ variable: PureVariable) {
        self = .binding(variable.binding)
    }
}

extension ImpureVariable: VariableType {
    public init(_ binding: Binding) {
        self = .binding(binding)
    }
    
    public var boundBinding: Binding? {
        switch self {
        case .binding(let binding):
            return binding
        case .constant:
            return nil
        }
    }
}

extension ImpureVariable: CustomStringConvertible {
    public var description: String {
        switch self {
        case .binding(let binding):
            return binding.description
        case .constant(let constant):
            return "\(constant)"
        }
    }
}
