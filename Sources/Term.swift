//
//  Term.swift
//  Calcula
//
//  Created by Jaden Geller on 12/21/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

public typealias PureTerm = Term<PureVariable>
public typealias ImpureTerm = Term<ImpureVariable>

public typealias Lambda = PureTerm

/// A lambda calculus term with no constrained constants.
public enum Term<Variable: VariableType> {
    /// Value that will be determined by the input of a lambda abstraction.
    case variable(Variable)
    
    /// Lambda abstraction capable of taking a single input and substituting it into the expression.
    indirect case lambda(Binding, Term)
    
    /// Application of the left hand term to the right hand term.
    indirect case application(Term, Term)
}

extension Term {
    public static var freeVariable: Term {
        return .variable(Variable(Binding()))
    }
    
    /// The set of identifiers that are not bound by a lambda abstraction.
    public var freeVariables: Set<Binding> {
        switch self {
        case .variable(let variable):
            guard let binding = variable.boundBinding else { return [] }
            return [binding]
        case .lambda(let argument, let lambda):
            return lambda.freeVariables.subtract([argument])
        case .application(let lhs, let rhs):
            return lhs.freeVariables.union(rhs.freeVariables)
        }
    }
}

extension Term {
    /// Returns the result of replacing all occurances of the variable `identifier` with `term`.
    @warn_unused_result public func substituting(binding: Binding, with term: Term) -> Term {
        switch self {
        case .variable(let variable):
            guard binding == variable.boundBinding else { return self }
            return term
        case let .lambda(argument, body) where argument != binding && argument.isFresh(in: term):
            return .lambda(argument, body.substituting(binding, with: term))

//            if  {
//                return .lambda(argument, body.substituting(binding, with: term))
//            } else {
//                let freshArgument = Binding()
//                let freshBody = body.substituting(argument, with: .variable(Variable(freshArgument)))
//                return .lambda(argument, freshBody.substituting(binding, with: term))
//            }
        case let .application(lhs, rhs):
            return .application(
                lhs.substituting(binding, with: term),
                rhs.substituting(binding, with: term)
            )
        default:
            return self
        }
    }
    
    /// Replaces all occurances of the variable `identifier` with `term`.
    mutating func substitute(binding: Binding, with term: Term) {
        self = substituting(binding, with: term)
    }
}

import Foundation
extension Term {
    /// Returns the result of performing beta-reduction on function application terms.
    @warn_unused_result public func reduced() -> Term {
        switch self {
        case .variable:
            return self
        case let .lambda(argument, body):
            return .lambda(argument, body.reduced())
        case let .application(lambda, value):
            let (lambda, value) = (lambda.reduced(), value.reduced())
            if case .lambda(let argument, let body) = lambda {
                return body.substituting(argument, with: value).reduced()
            } else {
                return .application(lambda, value)
            }
        }
    }
    
    /// Performs beta-reduction on function application terms.
    public mutating func reduce() {
        self = reduced()
    }
}

extension Term {
    public init(body: Term -> Term) {
        let argument = Binding()
        self = .lambda(argument, body(.variable(Variable(argument))))
    }
    
    public subscript(argument: Term) -> Term {
        return .application(self, argument)
    }
}

extension Term: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        var names: [Binding : String] = [:]
        return prettyDescription(reduced: true, names: &names)
    }
    
    public var debugDescription: String {
        return description(withNames: { String($0) }, reduced: false)
    }
    
    public func prettyDescription(reduced reduced: Bool, inout names: [Binding : String]) -> String {
        var identifierGenerator = LexiographicGenerator()
        return description(withNames: { binding in
            if let name = names[binding] {
                return name
            } else {
                let name = identifierGenerator.next()!
                names[binding] = name
                return name
            }
        }, reduced: reduced)
    }
    
    public func description(withNames name: (Binding -> String), reduced: Bool = true) -> String {
        switch reduced ? self.reduced() : self {
        case .variable(let variable):
            guard let binding = variable.boundBinding else { return String(variable) }
            return name(binding)
        case .lambda(let argument, let body):
            return "λ" + name(argument) + "." + body.description(withNames: name)
        case .application(let lhs, let rhs):
            func applicationTermDescription(term: Term) -> String {
                switch term {
                case .variable:
                    return term.description(withNames: name)
                case .lambda, .application:
                    return "(" + term.description(withNames: name) + ")"
                }
            }
            switch (lhs, rhs) {
            case (.variable, .variable), (.application, .variable):
                return lhs.description(withNames: name) + " " + rhs.description(withNames: name)
            case (.variable, _), (.application, _):
                return lhs.description(withNames: name) + "(" + rhs.description(withNames: name) + ")"
            case (.lambda, .variable):
                return "(" + lhs.description(withNames: name) + ")" + rhs.description(withNames: name)
            default:
                return "(" + lhs.description(withNames: name) + ")(" + rhs.description(withNames: name) + ")"
            }
        }
    }
}

//extension PureTerm { }
func unreducedEquals(lhs: PureTerm, _ rhs: PureTerm, withContext context: [Binding : Binding] = [:]) -> Bool {
    switch (lhs, rhs) {
    case (.variable(let leftVariable), .variable(let rightVariable)):
        return leftVariable.binding == rightVariable.binding || context[leftVariable.binding] == rightVariable.binding
    case (.lambda(let leftArgument, let leftBody), .lambda(let rightArgument, let rightBody)):
        var contextCopy = context
        contextCopy[leftArgument] = rightArgument
        return unreducedEquals(leftBody, rightBody, withContext: contextCopy)
    case (.application(let leftLhs, let leftRhs), .application(let rightLhs, let rightRhs)):
        return unreducedEquals(leftLhs, rightLhs, withContext: context) && unreducedEquals(leftRhs, rightRhs, withContext: context)
    default:
        return false
    }
}

//extension PureTerm: Equatable { }
public func ==(lhs: PureTerm, rhs: PureTerm) -> Bool {
    return unreducedEquals(lhs.reduced(), rhs.reduced())
}
public func !=(lhs: PureTerm, rhs: PureTerm) -> Bool {
    return !(lhs == rhs)
}

public enum EvaluationError<Variable: VariableType>: ErrorType, CustomStringConvertible {
    case lambdaResult(Term<Variable>)
    case boundResult(Variable)
    case expectedConstantFunction(Any)
    
    public var description: String {
        switch self {
        case .lambdaResult(let lambda):
            return "The result of the evaluation was unexpectedly a lambda: \(lambda)"
        case .boundResult(let variable):
            return "The result of the evaluation was unexpectedly an bound variable: \(variable)"
        case .expectedConstantFunction(let term):
            return "Expected constant function on left hand side of application, but found: \(term)"
        }
    }
}

// extension ImpureTerm
extension Term {
    public func constantValue() throws -> Any {
        guard self.dynamicType == ImpureTerm.self else { fatalError("Only `ImpureTerm` has a constant value.") }
        switch self.reduced() {
        case .variable(let variable):
            switch variable as! ImpureVariable {
            case .binding:
                throw EvaluationError.boundResult(variable)
            case .constant(let value):
                return value
            }
        case .lambda:
            throw EvaluationError.lambdaResult(self)

        case .application(let lhs, let rhs):
            let (lhsValue, rhsValue) = (try lhs.constantValue(), try rhs.constantValue())

            guard let lhsFunction = lhsValue as? Any -> Any else {
                throw EvaluationError.expectedConstantFunction(lhs) as EvaluationError<Variable>
            }
            return lhsFunction(rhsValue)
        }
    }
    
    public subscript(impureValue value: Any) -> ImpureTerm {
        guard let impureSelf = self as? ImpureTerm else { fatalError("Only `ImpureTerm` has a constant value.") }
        return impureSelf[.variable(.constant(value))]
    }
    
    public subscript(impureFunction function: Any -> Any) -> ImpureTerm {
        guard let impureSelf = self as? ImpureTerm else { fatalError("Only `ImpureTerm` has a constant value.") }
        return impureSelf[.variable(.constant(function))]
    }
}

extension Term {
    public func mapVariables<V: VariableType>(transform: Variable throws -> V) rethrows -> Term<V> {
        switch self {
        case .variable(let variable):
            return .variable(try transform(variable))
        case .lambda(let argument, let lambda):
            return .lambda(argument, try lambda.mapVariables(transform))
        case .application(let lhs, let rhs):
            return .application(try lhs.mapVariables(transform), try rhs.mapVariables(transform))
        }
    }
}


