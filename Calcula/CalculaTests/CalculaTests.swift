//
//  CalculaTests.swift
//  CalculaTests
//
//  Created by Jaden Geller on 12/21/15.
//  Copyright © 2015 Jaden Geller. All rights reserved.
//

import XCTest
@testable import Calcula

let t = Lambda { a in
    Lambda { b in
        a
    }
}
let f = Lambda { a in
    Lambda { b in
        b
    }
}
let and = Lambda { p in
    Lambda { q in
        p[q][p]
    }
}
let or = Lambda { p in
    Lambda { q in
        p[p][q]
    }
}
let not = Lambda { x in
    x[f][t]
}
let ifThenElse = Lambda { c in
    Lambda { t in
        Lambda { f in
            c[t][f]
        }
    }
}
let zero  = Lambda { f in Lambda { x in x } }
let one   = Lambda { f in Lambda { x in f[x] } }
let two   = Lambda { f in Lambda { x in f[f[x]] } }
let three = Lambda { f in Lambda { x in f[f[f[x]]] } }

let pair   = Lambda { x in Lambda { y in Lambda { f in f[x][y] } } }
let first  = Lambda { p in p[t] }
let second = Lambda { p in p[f] }
let none   = Lambda { x in t }
let isNone = Lambda { p in p[Lambda { x in Lambda { y in f } }] }

class CalculaTests: XCTestCase {

    func testPrint() {
        let f = Lambda { x in
            Lambda { y in
                y[x]
            }
        }
        XCTAssertEqual("λa.λb.(b)(a)", f.description)
    }
    
    func testEquality() {
        let t0 = Lambda { a in
            Lambda { b in
                a
            }
        }
        
        XCTAssertEqual(t, t0)
        XCTAssertNotEqual(t, f)
    }
    
    func testTrueFalse() {
        XCTAssertEqual("first",  t.unsafeApply(["first", "second"]) as? String)
        XCTAssertEqual("second", f.unsafeApply(["first", "second"]) as? String)
    }
    
    func testNot() {
        XCTAssertEqual(t, not[f])
        XCTAssertEqual(not[t], f)
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
        XCTAssertEqual(x[t][t], y[t][t])
        XCTAssertEqual(x[t][f], y[t][f])
        XCTAssertEqual(x[f][t], y[f][t])
        XCTAssertEqual(x[f][f], y[f][f])
    }
    
    func testIfThenEles() {
        _ = [true, false].flatMap { a in
            [true, false].flatMap { b in
                [true, false].flatMap { c in
                    XCTAssertEqual(ifThenElse[a ? t : f][b ? t : f][c ? t : f], (a ? b : c) ? t : f)
                }
            }
        }
    }
    
    func testNumerals() {
        let convert: [Any] = [{ (x: Any) -> Any in (x as! Int) + 1 }, 0]
        XCTAssertEqual(0, zero.unsafeApply(convert) as? Int)
        XCTAssertEqual(1, one.unsafeApply(convert) as? Int)
        XCTAssertEqual(2, two.unsafeApply(convert) as? Int)
        XCTAssertEqual(3, three.unsafeApply(convert) as? Int)
    }
    
    func testPairs() {
        let p = pair[three][two]
        XCTAssertEqual(three, first[p])
        XCTAssertEqual(two, second[p])
    }
    
    func testList() {
        let nums = [zero, one, two, three]
        var list = pair[zero][pair[one][pair[two][pair[three][none]]]];
        for i in 0...3 {
            XCTAssertEqual(nums[i], first[list])
            list = second[list]
        }
        XCTAssertEqual(t, isNone[list])
    }
}