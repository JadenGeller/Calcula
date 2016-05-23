//
//  TermTests.swift
//  CalculaTests
//
//  Created by Jaden Geller on 12/21/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

import XCTest
@testable import Calcula

class TermTests: XCTestCase {
    func testFreeVariables() {
        XCTAssertEqual([], Lambda { x in x }.freeVariables)
        
        let free = Binding()
        XCTAssertEqual([free], Term.application(
            Lambda { x in x },
            Term.variable(free)
        ).freeVariables)
    }
    
    func testCaptureAvoidingSubstitutions() {
        let (a, b, c) = (Binding(), Binding(), Binding())
        
        XCTAssert(
            Term.variable(b) ==
            Term.variable(a).substituting(a, with: Term.variable(b))
        )
        XCTAssert(
            Term.variable(a) ==
            Term.variable(a).substituting(b, with: Term.variable(c))
        )
        XCTAssert(
            Term.application(
                Term.variable(c),
                Term.variable(b)
            ) ==
            Term.application(
                Term.variable(a),
                Term.variable(b)
            ).substituting(a, with: Term.variable(c))
        )
        XCTAssert(
            Term.application(
                Term.variable(a),
                Term.variable(c)
            ) ==
            Term.application(
                Term.variable(a),
                Term.variable(b)
            ).substituting(b, with: Term.variable(c))
        )
        XCTAssert(
            Term.lambda(a, Term.variable(a)) ==
            Term.lambda(a, Term.variable(a)).substituting(a, with: Term.variable(b))
        )
        XCTAssert(
            Term.lambda(a, Term.variable(c)) ==
            Term.lambda(a, Term.variable(b)).substituting(b, with: Term.variable(c))
        )
        XCTAssert(
            Term.lambda(a, Term.variable(a)) !=
            Term.lambda(a, Term.variable(b)).substituting(b, with: Term.variable(a))
        )
    }
}
