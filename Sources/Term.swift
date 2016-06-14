//
//  Term.swift
//  Calcula
//
//  Created by Jaden Geller on 12/21/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

public func lambda(body: Term -> Term) -> Term {
    return Term(lambdaBody: body)
}

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
    public init(lambdaBody: Term -> Term) {
        let argument = Binding()
        self = .lambda(argument, lambdaBody(.variable(argument)))
    }
    
    public subscript(argument: Term) -> Term {
        return .application(self, argument)
    }
}

extension Term {
    public static func freeVariable() -> Term {
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
    public mutating func substitute(binding: Binding, with term: Term) {
        self = substituting(binding, with: term)
    }
}

import Foundation
extension Term {
    /// Returns the result of performing beta-reduction on function application terms.
    /// If `weakly` reduced, a lambda body will not be reduced.
    @warn_unused_result public func reduced(weakly weakly: Bool = false) -> Term {
        switch self {
        case .variable, .constant:
            return self
        case let .lambda(argument, body):
            return .lambda(argument, weakly ? body : body.reduced(weakly: false))
        case let .application(lambda, value):
            let (lambda, value) = (lambda.reduced(weakly: false), value.reduced(weakly: weakly))
            if case .lambda(let argument, let body) = lambda {
                return body.substituting(argument, with: value).reduced(weakly: weakly)
            } else {
                return .application(lambda, value)
            }
        }
    }
    
    /// Performs beta-reduction on function application terms.
    /// If `weakly` reduced, a lambda body will not be reduced.
    public mutating func reduce(weakly weakly: Bool = false) {
        self = reduced(weakly: weakly)
    }
}

extension Term {
    /// Returns `true` if `lhs` and `rhs` are structurally equal without doing any reduction, `false` otherwise.
    /// If a constant term is compared, will return `nil` to indicate comparison failed. (As a limitation of Swift,
    /// it is not possible to check if two `Any` values are equal.)
    // TODO: Once Equatable can be used as an existential in some way, update this and don't return an optional.
    public static func structurallyEqual(lhs: Term, _ rhs: Term, withContext context: [Binding : Binding] = [:]) -> Bool? {
        switch (lhs, rhs) {
        case (.constant, .constant):
            return nil
        case (.variable(let leftBinding), .variable(let rightBinding)):
            return leftBinding == rightBinding || context[leftBinding] == rightBinding
        case (.lambda(let leftArgument, let leftBody), .lambda(let rightArgument, let rightBody)):
            var contextCopy = context
            contextCopy[leftArgument] = rightArgument
            return structurallyEqual(leftBody, rightBody, withContext: contextCopy)
        case (.application(let leftLhs, let leftRhs), .application(let rightLhs, let rightRhs)):
            guard let leftEqual = structurallyEqual(leftLhs, rightLhs, withContext: context) else { return nil }
            guard leftEqual == true else { return false }
            guard let rightEqual = structurallyEqual(leftRhs, rightRhs, withContext: context) else { return nil }
            guard rightEqual == true else { return false }
            return true
        default:
            return false
        }
    }
}

public func ==(lhs: Term, rhs: Term) -> Bool? {
    return Term.structurallyEqual(lhs.reduced(), rhs.reduced())
}

