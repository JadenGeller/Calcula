//
//  Term.swift
//  Calcula
//
//  Created by Jaden Geller on 12/21/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

public enum Term {
    case Variable(Identifier)
    indirect case Capture(argument: Identifier, captured: Term)
    indirect case Application(Term, Term)
}

extension Term {
    func isFresh(match: Identifier) -> Bool {
        switch self {
        case .Variable:
            return true
        case let .Capture(argument, captured):
            return argument != match && captured.isFresh(match)
        case let .Application(lhs, rhs):
            return lhs.isFresh(match) && rhs.isFresh(match)
        }
    }
    
    func substituted(match: Identifier, with value: Term) -> Term {
        switch self {
        case let .Variable(variable) where variable == match:
            return value
        case let .Capture(argument, term) where argument != match:
            if value.isFresh(argument) {
                return .Capture(argument: argument, captured: term.substituted(match, with: value))
            } else {
                let freshArgument = Identifier()
                let freshTerm = term.substituted(argument, with: .Variable(freshArgument))
                return .Capture(argument: freshArgument, captured: freshTerm.substituted(match, with: value))
            }
        case let .Application(lhs, rhs):
            return .Application(lhs.substituted(match, with: value), rhs.substituted(match, with: value))
        default:
            return self
        }
    }
    
    func reduced() -> Term {
        switch self {
        case .Variable:
            return self
        case let .Capture(argument, captured):
            return .Capture(argument: argument, captured: captured.reduced())
        case let .Application(lambda, value):
            switch lambda.reduced() {
            case let .Variable(variable):
                return .Application(.Variable(variable), value)
            case let .Capture(argument, captured):
                return captured.substituted(argument, with: value).reduced()
            case .Application:
                return self
            }
        }
    }
}

extension Term {
    func prettyDescription<G: GeneratorType where G.Element == String>(var withExistingNames names: [Identifier : String] = [:], inout nameGenerator: G) -> String {
        
        func getName(identifier: Identifier) -> String {
            if let name = names[identifier] { return name }
            else {
                let name = nameGenerator.next()
                names[identifier] = name
                return name! // crashes if it generates nil
            }
        }
        
        switch self {
        case let .Variable(identifier):
            return getName(identifier)
        case let .Capture(argument, captured):
            let argumentName = getName(argument)
            let capturedDescription = captured.prettyDescription(withExistingNames: names, nameGenerator: &nameGenerator)
            return "λ" + argumentName + "." + capturedDescription
        case let .Application(lhs, rhs):
            let first = lhs.prettyDescription(withExistingNames: names, nameGenerator: &nameGenerator)
            let second = rhs.prettyDescription(withExistingNames: names, nameGenerator: &nameGenerator)
            return "(" + first + ")(" + second + ")"
        }
    }
}

extension Term {
    func unreducedIsEqual(other: Term, withEquivalencies equivalent: [Identifier : Identifier] = [:]) -> Bool {
        switch (self, other) {
        case let (.Capture(argument, captured), .Capture(otherArgument, otherCaptured)):
            var equivalent = equivalent
            equivalent[argument] = otherArgument
            return captured.unreducedIsEqual(otherCaptured, withEquivalencies: equivalent)
        case let (.Variable(a), .Variable(b)):
            return a == b || equivalent[a] == b
        case let (.Application(a1, a2), .Application(b1, b2)):
            return a1.unreducedIsEqual(b1, withEquivalencies: equivalent) && a2.unreducedIsEqual(b2, withEquivalencies: equivalent)
        default:
            return false
        }
    }
}
