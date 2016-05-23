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
            Term.variable(PureVariable(free))
        ).freeVariables)
    }
    
    func testCaptureAvoidingSubstitutions() {
        let (a, b, c) = (Binding(), Binding(), Binding())
        
        XCTAssert(
            Term.variable(PureVariable(b)) ==
            Term.variable(PureVariable(a)).substituting(a, with: Term.variable(PureVariable(b)))
        )
        XCTAssert(
            Term.variable(PureVariable(a)) ==
            Term.variable(PureVariable(a)).substituting(b, with: Term.variable(PureVariable(c)))
        )
        XCTAssert(
            Term.application(
                Term.variable(PureVariable(c)),
                Term.variable(PureVariable(b))
            ) ==
            Term.application(
                Term.variable(PureVariable(a)),
                Term.variable(PureVariable(b))
            ).substituting(a, with: Term.variable(PureVariable(c)))
        )
        XCTAssert(
            Term.application(
                Term.variable(PureVariable(a)),
                Term.variable(PureVariable(c))
            ) ==
            Term.application(
                Term.variable(PureVariable(a)),
                Term.variable(PureVariable(b))
            ).substituting(b, with: Term.variable(PureVariable(c)))
        )
        XCTAssert(
            Term.lambda(a, Term.variable(PureVariable(a))) ==
            Term.lambda(a, Term.variable(PureVariable(a))).substituting(a, with: Term.variable(PureVariable(b)))
        )
        XCTAssert(
            Term.lambda(a, Term.variable(PureVariable(c))) ==
            Term.lambda(a, Term.variable(PureVariable(b))).substituting(b, with: Term.variable(PureVariable(c)))
        )
        XCTAssert(
            Term.lambda(a, Term.variable(PureVariable(a))) !=
            Term.lambda(a, Term.variable(PureVariable(b))).substituting(b, with: Term.variable(PureVariable(a)))
        )
    }
}
