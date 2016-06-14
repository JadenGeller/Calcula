//
//  LambdaTests.swift
//  CalculaTests
//
//  Created by Jaden Geller on 12/21/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

import XCTest
@testable import Calcula

let y = lambda { f in lambda { x in f[x[x]] }[lambda { x in f[x[x]] }] }

// MARK: Boolean Operators

let and = lambda { p in lambda { q in p[q][p] } }
let or = lambda { p in lambda { q in p[p][q] } }
let not = lambda { x in x[false][true] }
let ifThenElse = lambda { c in lambda { t in lambda { f in c[t][f] } } }

// MARK: Numeral Operators

let succ = lambda { x in lambda { s in lambda { z in s[x[s][z]] } } }
let isZero = lambda { x in x[lambda { _ in false }][true] }
//let fact = y[lambda { recurse in
//    lambda { x in ifThenElse[isZero[x]][1][mult[x][fact[pred[x]]]] }
//}]

// MARK: Pair Operators

let pair   = lambda { l in lambda { r in lambda { f in f[l][r] } } }
let first  = lambda { p in p[true] }
let second = lambda { p in p[false] }

// MARK: Optional Operators

let some    = lambda { x in pair[true][x] }
let none    = pair[false][false]
let isSome  = lambda { p in first[p] }
let unwrap  = lambda { p in second[p] }
let mapSome = lambda { f in lambda { p in ifThenElse[isSome[p]][some[f[unwrap[p]]]][none] } }
let flatMapSome = lambda { f in lambda { p in ifThenElse[isSome[p]][f[unwrap[p]]][none] } }

// MARK: List Operators

let cons = lambda { x in lambda { xs in some[pair[x][xs]] } }
let head = mapSome[first]
let tail = flatMapSome[second]
//let mapList = y[lambda { recurse in
//    lambda { f in lambda { l in ifThenElse[isSome[l]][cons[f[unwrap[head[l]]]][recurse[tail[l]]]][none] } }
//}]

// MARK: Tests

class LambdaTests: XCTestCase {

    // TODO: Separation of tests into files doesn't make sense
    func testPrint() {
        let (w, x, y) = (Binding(), Binding(), Binding())
        XCTAssertEqual(
            "λa.λb.b a",
            Term.lambda(x, .lambda(y, .application(.variable(y), .variable(x)))).description
        )
        XCTAssertEqual(
            "a b c",
            Term.application(
                Term.application(.variable(w), .variable(x)),
                .variable(y)
            ).description
        )
        XCTAssertEqual(
            "a(b c)",
            Term.application(
                .variable(y),
                Term.application(.variable(w), .variable(x))
                ).description
        )
        XCTAssertEqual(
            "λa.b c",
            Term.lambda(w, Term.application(.variable(x), .variable(y))).description
        )
    }
    
    func testParse() {
        let (a, b, c) = (Binding(), Binding(), Binding())
        var bindings = ["a" : a, "b" : b, "c" : c]
        XCTAssert(Term.structurallyEqual(
            try! Term(parsing: "λa.λb.b a", withExistingBindings: &bindings),
            Term.lambda(a, .lambda(b, .application(.variable(b), .variable(a))))
        ) ?? false)
        XCTAssert(Term.structurallyEqual(
            try! Term(parsing: "a b c", withExistingBindings: &bindings),
            Term.application(
                Term.application(.variable(a), .variable(b)),
                .variable(c)
            )
        ) ?? false)
        XCTAssert(Term.structurallyEqual(
            try! Term(parsing: "a(b c)", withExistingBindings: &bindings),
            Term.application(
                .variable(a),
                Term.application(.variable(b), .variable(c))
            )
        ) ?? false)
        XCTAssert(Term.structurallyEqual(
            try! Term(parsing: "λa.b c", withExistingBindings: &bindings),
            Term.lambda(a, Term.application(.variable(b), .variable(c)))
        ) ?? false)
    }
    
    func testSubstitution() {
        let (x, y, t, r) = (Binding(), Binding(), Binding(), Binding())
        XCTAssert(Term.structurallyEqual(
            Term.variable(x).substituting(x, with: .variable(r)),
            Term.variable(r)
        ) ?? false)
        XCTAssert(Term.structurallyEqual(
            Term.variable(y).substituting(x, with: .variable(r)),
            Term.variable(y)
        ) ?? false)
        XCTAssert(Term.structurallyEqual(
            Term.lambda(x, .variable(t)).substituting(x, with: .variable(r)),
            Term.lambda(x, .variable(t))
        ) ?? false)
        XCTAssert(Term.structurallyEqual(
            Term.lambda(x, .variable(x)).substituting(y, with: .variable(y)),
            Term.lambda(x, .variable(x))
        ) ?? false)
        XCTAssert(Term.structurallyEqual(
            Term.application(.lambda(x, .variable(y)), .variable(x)).substituting(x, with: .variable(y)),
            Term.application(.lambda(x, .variable(y)), .variable(y))
        ) ?? false)
        XCTAssert(Term.structurallyEqual(
            Term.lambda(x, .variable(y)).substituting(y, with: .variable(x)),
            Term.lambda(x, .variable(x))
        ) == false)
    }
    
    func testEquality() {
        XCTAssert(Term.structurallyEqual(
            true,
            lambda { a in lambda { b in a } }
        ) ?? false)
        XCTAssert(Term.structurallyEqual(
            true,
            false
        ) == false)
    }
    
    func testTrueFalse() {
        XCTAssertEqual(0, try! (true as Term).applying(0).applying(1).evaluated())
        XCTAssertEqual(1, try! (false as Term).applying(0).applying(1).evaluated())
    }
    
    func testNot() {
        XCTAssert((true == not[false]) ?? false)
        XCTAssert((not[true] == false) ?? false)
    }

    func testAndOr() {
        let x = lambda { a in
            lambda { b in
                not[or[a][b]]
            }
        }
        let y = lambda { a in
            lambda { b in
                and[not[a]][not[b]]
            }
        }
        XCTAssert((x[true][true] == y[true][true]) ?? false)
        XCTAssert((x[true][false] == y[true][false]) ?? false)
        XCTAssert((x[false][true] == y[false][true]) ?? false)
        XCTAssert((x[false][false] == y[false][false]) ?? false)
    }

    func testIfThenElse() {
        let (a, b) = (Term.variable(Binding()), Term.variable(Binding()))
        for condition in [true, false] {
            XCTAssert((ifThenElse[condition ? true : false][a][b] == (condition ? a : b)) ?? false)
        }
    }

    func testNumerals() {
        for i in 0...10 {
            XCTAssertEqual(i, Int(churchEncoded: Term(churchEncoding: i)))
        }
    }
    
    func testPairs() {
        let p = pair[3][2]
        XCTAssert((3 == first[p]) ?? false)
        XCTAssert((2 == second[p]) ?? false)
    }

    func testSucc() {
        for x in (1...5) {
            for y in (1...5) {
                let a = Term(churchEncoding: x + y)
                let b = (0..<y).reduce(Term(churchEncoding: x), combine: { term, _ in succ[term] })

                XCTAssert((a == b) ?? false)
            }
        }
    }

    func testOptional() {
        let a = some[Term(integerLiteral: 5)]
        XCTAssert(Bool(churchEncoded: isSome[a]) ?? false)
        XCTAssert((unwrap[a] == 5) ?? false)
        let b = mapSome[succ][a]
        XCTAssert(Bool(churchEncoded: isSome[b]) ?? false)
        XCTAssert((unwrap[b] == 6) ?? false)
    }
    
    func testList() {
        let range = 0...3
        var list = none
        XCTAssert(!(Bool(churchEncoded: isSome[list]) ?? false))
        for i in range {
            let oldList = list
            let n = Term(churchEncoding: i)
            list = cons[n][list] // -> [3, 2, 1, 0]
            XCTAssert(Bool(churchEncoded: isSome[list]) ?? false)
            XCTAssert((n == first[unwrap[list]]) ?? false)
            XCTAssert((n == unwrap[head[list]]) ?? false)
            XCTAssert((oldList == second[unwrap[list]]) ?? false)
            XCTAssert((oldList == tail[list]) ?? false)
        }
//        list = mapList[succ][list]
//        let range2 = 1...4
        for i in range.reverse() {
            guard Bool(churchEncoded: isSome[list]) ?? false else { fatalError() }
            XCTAssert(Bool(churchEncoded: isSome[list]) ?? false)
            XCTAssertEqual(i, Int(churchEncoded: unwrap[head[list]]))
            print(Int(churchEncoded: unwrap[head[list]]))
            list = tail[list]
        }
        XCTAssert(!(Bool(churchEncoded: isSome[list]) ?? false))
    }
}

