//
//  Term.swift
//  Calcula
//
//  Created by Jaden Geller on 12/21/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

public struct Lambda {
    internal let backing: Term
    
    public init<T: TermConvertible>(@noescape _ implementation: Identifier -> T) {
        let identifier = Identifier()
        self.backing = .Capture(argument: identifier, captured: implementation(identifier).termValue)
    }
    
    internal init(backing: Term) {
        self.backing = backing
    }
}

extension Lambda: CustomStringConvertible {
    public var description: String {
        var state = [-1]
        var nameGenerator = anyGenerator { () -> String? in
            // increment state
            state[0] += 1
            
            // ripple carry
            var n = 0
            while state[n] > 26 {
                state[n] = 0
                if n + 1 == state.count { state.append(-1) }
                state[n + 1] += 1
                n += 1
            }
            
            return String(state.map{ Character(UnicodeScalar(97 + $0)) })
        }
        return backing.prettyDescription(nameGenerator: &nameGenerator)
    }
}

extension Lambda: Equatable {}
public func ==(lhs: Lambda, rhs: Lambda) -> Bool {
    return lhs.backing.unreducedIsEqual(rhs.backing)
}

extension Lambda {
    func unsafeApply(values: [Any]) -> Any? {
        switch backing {
        case let .Variable(identifier):
            guard let data = identifier as? Data else { return nil }
            return data.value
        case let .Capture(argument, captured):
            let term = captured.substituted(argument, with: .Variable(Data(values.first!)))
            return Lambda(backing: term).unsafeApply(Array(values.dropFirst()))
        case let .Application(lhs, rhs):
            guard case let .Variable(identifier) = lhs else { return nil }
            guard let data = identifier as? Data else { return nil }
            guard let function = data.value as? Any -> Any else { return nil }
            guard let argument = Lambda(backing: rhs).unsafeApply([]) else { return nil }
            return function(argument)
        }
    }
}

