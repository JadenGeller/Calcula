//
//  TermConvertible.swift
//  Calcula
//
//  Created by Jaden Geller on 12/21/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

protocol TermConvertible {
    var termValue: Term { get }
}

extension Term: TermConvertible {
    var termValue: Term { return self }
}

extension Identifier: TermConvertible {
    var termValue: Term { return .Variable(self) }
}

extension Lambda: TermConvertible {
    var termValue: Term { return backing }
}

extension TermConvertible {
    subscript(argument: TermConvertible) -> Lambda {
        return Lambda(backing: Term.Application(termValue, argument.termValue).reduced())
    }
}