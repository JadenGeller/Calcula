//
//  Term.swift
//  Calcula
//
//  Created by Jaden Geller on 12/21/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

// TODO: Make this type hide Term and automatically reduce stuff.
public typealias Lambda = Term

/// A lambda calculus term.
public enum Term {
    // Constained constant.
    case constant(Any)

    /// Value that will be determined by the input of a lambda abstraction.
    case variable(Binding)

    /// Lambda abstraction capable of taking a single input and substituting it into the expression.
    indirect case lambda(Binding, Term)
    
    /// Application of the left hand term to the right hand term.
    indirect case application(Term, Term)
}

extension Term {
    public static var freeVariable: Term {
        return .variable(Binding())
    }
    
    /// The set of identifiers that are not bound by a lambda abstraction.
    public var freeVariables: Set<Binding> {
        switch self {
        case .constant:
            return []
        case .variable(let binding):
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
        case .variable(binding):
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
        case .variable, .constant:
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
        self = .lambda(argument, body(.variable(argument)))
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
    
    private var isTightlyBound: Bool {
        switch self {
        case .variable, .constant:
            return true
        case .application, .lambda:
            return false
        }
    }
    
    public func description(withNames name: (Binding -> String), reduced: Bool = true) -> String {
        switch reduced ? self.reduced() : self {
        case .constant(let value):
            return String(value)
        case .variable(let binding):
            return name(binding)
        case .lambda(let argument, let body):
            return "λ" + name(argument) + "." + body.description(withNames: name)
        case .application(let lhs, let rhs):
            switch (lhs, rhs) {
            case (.variable, let r) where r.isTightlyBound:
                return lhs.description(withNames: name) + " " + rhs.description(withNames: name)
            case (.application, let r) where r.isTightlyBound:
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

extension Term {
    /// Returns `true` if `lhs` and `rhs` are structurally equal without doing any reduction, `false` otherwise.
    /// If a constant term is compared, will return `nil` to indicate comparison failed. (As a limitation of Swift,
    /// it is not possible to check if two `Any` values are equal.)
    // SWIFT: Once Equatable can be used as an existential in some way, update this.
    public static func unreducedEquals(lhs: Term, _ rhs: Term, withContext context: [Binding : Binding] = [:]) -> Bool? {
        switch (lhs, rhs) {
        case (.constant, .constant):
            return nil
        case (.variable(let leftBinding), .variable(let rightBinding)):
            return leftBinding == rightBinding || context[leftBinding] == rightBinding
        case (.lambda(let leftArgument, let leftBody), .lambda(let rightArgument, let rightBody)):
            var contextCopy = context
            contextCopy[leftArgument] = rightArgument
            return unreducedEquals(leftBody, rightBody, withContext: contextCopy)
        case (.application(let leftLhs, let leftRhs), .application(let rightLhs, let rightRhs)):
            guard let leftEqual = unreducedEquals(leftLhs, rightLhs, withContext: context) else { return nil }
            guard leftEqual == true else { return false }
            guard let rightEqual = unreducedEquals(leftRhs, rightRhs, withContext: context) else { return nil }
            guard rightEqual == true else { return false }
            return true
        default:
            return false
        }
    }
}

// TODO: Remove this shit and add on `Lambda`
// More specially, make it less magical
//extension PureTerm: Equatable { }
public func ==(lhs: Term, rhs: Term) -> Bool {
    guard let isEqual = Term.unreducedEquals(lhs.reduced(), rhs.reduced()) else {
        fatalError("Checking equality between terms with constant values is undefined.")
    }
    return isEqual
}
public func !=(lhs: Term, rhs: Term) -> Bool {
    return !(lhs == rhs)
}

public enum EvaluationError: ErrorType, CustomStringConvertible {
    case lambdaResult(Term)
    case boundResult(Binding)
    case expectedConstantFunction(Any)
    
    public var description: String {
        switch self {
        case .lambdaResult(let lambda):
            return "The result of the evaluation was unexpectedly a lambda: \(lambda)"
        case .boundResult(let binding):
            return "The result of the evaluation was unexpectedly an bound variable: \(binding)"
        case .expectedConstantFunction(let term):
            return "Expected constant function on left hand side of application, but found: \(term)"
        }
    }
}

extension Term {
    // TODO: Remove this shit and add on `Lambda`
    // TODO: Rename `evaluateConstant`
    public func constantValue() throws -> Any {
        switch self.reduced() {
        case .constant(let value):
            return value
        case .variable(let binding):
            throw EvaluationError.boundResult(binding)
        case .lambda:
            throw EvaluationError.lambdaResult(self)

        case .application(let lhs, let rhs):
            let (lhsValue, rhsValue) = (try lhs.constantValue(), try rhs.constantValue())

            guard let lhsFunction = lhsValue as? Any -> Any else {
                throw EvaluationError.expectedConstantFunction(lhs)
            }
            return lhsFunction(rhsValue)
        }
    }
    
    // TODO: Remove this shit and add on `Lambda`
    public subscript(impureValue value: Any) -> Term {
        return self[.constant(value)]
    }
    
    public subscript(impureFunction function: Any -> Any) -> Term {
        return self[.constant(function)]
    }
}

