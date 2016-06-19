//
//  Term+Reduction.swift
//  Calcula
//
//  Created by Jaden Geller on 6/18/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

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

public func ==(lhs: Term, rhs: Term) -> Bool? {
    return Term.structurallyEqual(lhs.reduced(), rhs.reduced())
}
