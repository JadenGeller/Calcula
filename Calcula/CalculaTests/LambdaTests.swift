//
//  LambdaTests.swift
//  CalculaTests
//
//  Created by Jaden Geller on 12/21/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

import XCTest
@testable import Calcula

extension Term: BooleanLiteralConvertible {
    public init(booleanLiteral value: Bool) {
        self = Term { t in Term { f in value ? t : f } }
    }
}
let and = Lambda { p in Lambda { q in p[q][p] } }
let or = Lambda { p in Lambda { q in p[p][q] } }
let not = Lambda { x in x[false][true] }
let ifThenElse = Lambda { c in Lambda { t in Lambda { f in c[t][f] } } }

extension Term: IntegerLiteralConvertible {
    public init(integerLiteral value: Int) {
        assert(value >= 0)
        self = Term { z in
            Term { s in
                var result = z
                for _ in 0..<value {
                    result = s[result]
                }
                return result
            }
        }
    }
}
extension Term {
    public func integerValue() throws -> Int {
        let succ: Any -> Any = { $0 as! Int + 1 }
        return try self[impureValue: 0][impureFunction: succ].constantValue() as! Int
    }
}

let succ = Lambda { a in Lambda { z in Lambda { s in s[a[z][s]] } } }

let pair   = Lambda { l in Lambda { r in Lambda { f in f[l][r] } } }
let first  = Lambda { p in p[true] }
let second = Lambda { p in p[false] }

let some    = Lambda { x in pair[true][x] }
let none    = pair[false][false]
let isSome  = Lambda { p in first[p] }
let unwrap  = Lambda { p in second[p] }
let mapSome = Lambda { f in Lambda { p in ifThenElse[isSome[p]][some[f[unwrap[p]]]][none] } }

let cons = Lambda { x in Lambda { xs in some[pair[x][xs]] } }
let head = Lambda { l in mapSome[first] }
let tail = Lambda { l in mapSome[second] }

class LambdaTests: XCTestCase {

    func testPrint() {
        let (w, x, y) = (Binding(), Binding(), Binding())
        XCTAssertEqual(
            "λa.λb.b a",
            Term.lambda(x, .lambda(y, .application(.variable(PureVariable(y)), .variable(PureVariable(x))))).description
        )
        XCTAssertEqual(
            "a b c",
            Term.application(
                Term.application(.variable(PureVariable(w)), .variable(PureVariable(x))),
                .variable(PureVariable(y))
            ).description
        )
        XCTAssertEqual(
            "a(b c)",
            Term.application(
                .variable(PureVariable(y)),
                Term.application(.variable(PureVariable(w)), .variable(PureVariable(x)))
            ).description
        )
        XCTAssertEqual(
            "λa.b c",
            Term.lambda(w, Term.application(.variable(PureVariable(x)), .variable(PureVariable(y)))).description
        )
    }
    
    func testSubstitution() {
        let (x, y, t, r) = (Binding(), Binding(), Binding(), Binding())
        XCTAssert(unreducedEquals(
            Term.variable(PureVariable(x)).substituting(x, with: .variable(PureVariable(r))),
            Term.variable(PureVariable(r))
        ))
        XCTAssert(unreducedEquals(
            Term.variable(PureVariable(y)).substituting(x, with: .variable(PureVariable(r))),
            Term.variable(PureVariable(y))
        ))
        XCTAssert(unreducedEquals(
            Term.lambda(x, .variable(PureVariable(t))).substituting(x, with: .variable(PureVariable(r))),
            Term.lambda(x, .variable(PureVariable(t)))
        ))
        XCTAssert(unreducedEquals(
            Term.lambda(x, .variable(PureVariable(x))).substituting(y, with: .variable(PureVariable(y))),
            Term.lambda(x, .variable(PureVariable(x)))
        ))
        XCTAssert(unreducedEquals(
            Term.application(.lambda(x, .variable(PureVariable(y))), .variable(PureVariable(x))).substituting(x, with: .variable(PureVariable(y))),
            Term.application(.lambda(x, .variable(PureVariable(y))), .variable(PureVariable(y)))
        ))
        XCTAssertFalse(unreducedEquals(
            Term.lambda(x, .variable(PureVariable(y))).substituting(y, with: .variable(PureVariable(x))),
            Term.lambda(x, .variable(PureVariable(x)))
        ))
    }
    
    func testEquality() {
        let t0 = Lambda { a in
            Lambda { b in
                a
            }
        }
        
        print(t0.description)
        print((true as Lambda).description)
        XCTAssert(true == t0)
        XCTAssert(true != false as Lambda)
    }
    
    func testTrueFalse() {
        print((false as ImpureTerm)[impureValue: 0][impureValue: 1].reduced())
        XCTAssertEqual(0, try! (true as ImpureTerm)[impureValue: 0][impureValue: 1].constantValue() as! Int)
        XCTAssertEqual(1, try! (false as ImpureTerm)[impureValue: 0][impureValue: 1].constantValue() as! Int)
    }
    
    func testNot() {
        print(not[false].reduced())
        XCTAssert(true == not[false])
        XCTAssert(not[true] == false)
    }
    
    func testAndOr() {
        let x = Lambda { a in
            Lambda { b in
                not[or[a][b]]
            }
        }
        let y = Lambda { a in
            Lambda { b in
                and[not[a]][not[b]]
            }
        }
//        print(x)
//        print(x.reduced())
//        print(x[true][true])
        print(x[true][true].reduced())
        XCTAssert(x[true][true] == y[true][true])
        XCTAssert(x[true][false] == y[true][false])
        XCTAssert(x[false][true] == y[false][true])
        XCTAssert(x[false][false] == y[false][false])
    }
    
//    λa.λb.(λc.c(λd.λe.e)(λf.λg.f))((λh.λi.h h i)a b)

//        
    func testIfThenEles() {
        for a in [true, false] {
            for b in [true, false] {
                for c in [true, false] {
                    XCTAssert(ifThenElse[a ? true : false][b ? true : false][c ? true : false] == ((a ? b : c) ? true : false))
                }
            }
        }
    }
    
    
    func testNumerals() {
        for i in 0...10 {
            XCTAssertEqual(i, try! ImpureTerm(integerLiteral: i).integerValue())
        }
    }
    
    func testPairs() {
        let p = pair[3][2]
        XCTAssert(3 == first[p])
        XCTAssert(2 == second[p])
    }
    
    func testMath() {
        for x in (1...5) {
            for y in (1...5) {
                let n = Lambda(integerLiteral: x)
                let m = Lambda(integerLiteral: x + y)
                
                var z = n
                for _ in 0..<y {
                    z = succ[z]
                }
                
                let zz = z.reduced()
                let mm = m.reduced()
                XCTAssert(unreducedEquals(zz, mm))
            }
        }
    }
    
    func testOptional() {
        let a = some[Term(integerLiteral: 5)]
        XCTAssert(isSome[a] == true)
        XCTAssert(unwrap[a] == Term(integerLiteral: 5))
        let b = mapSome[succ][a]
        XCTAssert(isSome[b] == true)
        XCTAssert(unwrap[b] == Term(integerLiteral: 6))
    }
    
//    func testList() {
//        let range = 0...3
//        var list = none
//        XCTAssert(false == isSome[list])
//        for i in range {
//            list = cons[Term(integerLiteral: i)][list] // -> [3, 2, 1, 0]
//            XCTAssert(true == isSome[list])
//            print(list)
//        }
//        for i in range.reverse() {
//            // TODO: Make everythign impure...
//            let impureList = list.mapVariables(ImpureVariable.init)
//            let x = try! unwrap.mapVariables(ImpureVariable.init)[head.mapVariables(ImpureVariable.init)[impureList]].integerValue()
//            print(x)
//            XCTAssert(true == isSome[list])
//            XCTAssert(Term(integerLiteral: i) == unwrap[head[list]])
//            list = tail[list]
//            print(list)
//        }
//        XCTAssert(false == isSome[list])
//    }
}
