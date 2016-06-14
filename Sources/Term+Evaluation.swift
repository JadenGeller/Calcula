//
//  Impure.swift
//  Calcula
//
//  Created by Jaden Geller on 5/22/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

public enum EvaluationError: ErrorType, CustomStringConvertible {
    case lambdaResult(Term)
    case boundResult(Binding)
    case expectedConstantFunction(Any)
    case dynamicCastFailure(Any, Any.Type)
    case dynamicCastArgumentFailure // TODO
    
    // TODO: These are bad errors
    public var description: String {
        switch self {
        case .lambdaResult(let lambda):
            return "The result of the evaluation was unexpectedly a lambda: `\(lambda)`"
        case .boundResult(let binding):
            return "The result of the evaluation was unexpectedly a bound variable: `\(binding)`"
        case .expectedConstantFunction(let term):
            return "Expected constant function on left hand side of application, but found `\(term)`"
        case .dynamicCastFailure(let value, let type):
            return "Unable to cast `\(value)` from type `\(value.dynamicType)` to type `\(type)`)"
        case .dynamicCastArgumentFailure:
            return "Dynamic cast argument failure"
        }
    }
}

extension Term {
    public func evaluated<V>() throws -> V {
        let term = reduced(weakly: true)
        switch term {
        case .constant(let untypedValue):
            guard let value = untypedValue as? V else {
                throw EvaluationError.dynamicCastFailure(untypedValue, V.self)
            }
            return value
        case .variable(let binding):
            throw EvaluationError.boundResult(binding)
        case .lambda:
            throw EvaluationError.lambdaResult(term)
            
        case .application(let lhs, let rhs):
            let (untypedFunction, argument): (Any, Any) = (try lhs.evaluated(), try rhs.evaluated())
            
            guard let function = untypedFunction as? Any throws -> Any else {
                throw EvaluationError.expectedConstantFunction(untypedFunction)
            }
            return try Term.constant(function(argument)).evaluated()
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
                throw EvaluationError.dynamicCastArgumentFailure
            }
            return function(argument)
        }, lazily: lazily)
    }
    
    public mutating func apply<T, V>(function: (T -> V), lazily: Bool = false) {
        self = applying(function)
    }
}


