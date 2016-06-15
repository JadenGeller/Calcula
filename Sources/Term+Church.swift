//
//  Term+Numerals.swift
//  Calcula
//
//  Created by Jaden Geller on 6/12/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

// TODO: Put in submodule once Swift supports this.

// MARK: Church Numeral

extension Term: IntegerLiteralConvertible {
    public init(churchEncoding value: Int) {
        precondition(value >= 0, "Church numerals may only encode positive integers.")
        self = Term { successor in
            Term { zero in
                (0..<value).reduce(zero, combine: { term, _ in successor[term] })
            }
        }
    }
    
    public init(integerLiteral value: Int) {
        self = Term(churchEncoding: value)
    }
}

extension Int {
    public init?(churchEncoded term: Term) {
        guard let value = try? term
            .applying({ (value: Int) -> Int in value + 1 })
            .applying(0)
            .evaluated() as Int else { return nil }
        self = value
    }
}

// MARK: Church Boolean

extension Term: BooleanLiteralConvertible {
    public init(churchEncoding value: Bool) {
        self = Calcula.lambda { t in Calcula.lambda { f in value ? t : f } }
    }
    
    public init(booleanLiteral value: Bool) {
        self = Calcula.lambda { t in Calcula.lambda { f in value ? t : f } }
    }
}

extension Bool {
    public init?(churchEncoded term: Term) {
        guard let value = try? term.applying(true).applying(false).evaluated() as Bool else { return nil }
        self = value
    }
}



