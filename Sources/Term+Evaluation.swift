//
//  Impure.swift
//  Calcula
//
//  Created by Jaden Geller on 5/22/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

public enum EvaluationError: ErrorType, CustomStringConvertible {
    public enum Purpose: String {
        case function
        case argument
        case result
    }
    case expectedConstant(found: Term)
    case dynamicCastFailure(purpose: Purpose, value: Any, targetType: Any.Type)
    
    // TODO: These are bad errors
    public var description: String {
        switch self {
        case .expectedConstant(let found):
            return "The result of the evaluation was unexpectedly: `\(found)`"
        case .dynamicCastFailure(let purpose, let value, let targetType):
            return "Unable to cast `\(value)` from type `\(value.dynamicType)` to type `\(targetType)` for use as constant \(purpose)"
        }
    }
}

extension Term {
    public func evaluated<V>() throws -> V {
        let term = reduced(weakly: true)
        switch term {
        case .constant(let untypedValue):
            guard let value = untypedValue as? V else {
                throw EvaluationError.dynamicCastFailure(purpose: .argument, value: untypedValue, targetType: V.self)
            }
            return value
        case .application(let lhs, let rhs):
            let (untypedFunction, argument): (Any, Any) = (try lhs.evaluated(), try rhs.evaluated())
            
            typealias AnyFunction = Any throws -> Any
            guard let function = untypedFunction as? AnyFunction else {
                throw EvaluationError.dynamicCastFailure(purpose: .function, value: untypedFunction, targetType: AnyFunction.self)
            }
            return try Term.constant(function(argument)).evaluated()
        case .variable, .lambda:
            throw EvaluationError.expectedConstant(found: term)
        }
    }
}

extension Term {
    // MARK: Term
    
    @warn_unused_result public func applying(value: Term, lazily: Bool = false) -> Term {
        return self[value].reduced(weakly: lazily)
    }
    
    public mutating func apply(value: Term, lazily: Bool = false) {
        self = applying(value, lazily: lazily)
    }
    
    // MARK: Value
    
    @warn_unused_result public func applying<T>(value: T, lazily: Bool = false) -> Term {
        return applying(.constant(value)).reduced(weakly: lazily)
    }
    
    public mutating func apply<T>(value: T, lazily: Bool = false) {
        self = applying(value, lazily: lazily)
    }

    // MARK: Function
    
    @warn_unused_result public func applying<T, V>(function: (T -> V), lazily: Bool = false) -> Term {
        return applying({ (untypedArgument: Any) throws -> Any in
            guard let argument = untypedArgument as? T else {
                throw EvaluationError.dynamicCastFailure(purpose: .result, value: untypedArgument, targetType: T.self)
            }
            return function(argument)
        }, lazily: lazily)
    }
    
    public mutating func apply<T, V>(function: (T -> V), lazily: Bool = false) {
        self = applying(function)
    }
}


