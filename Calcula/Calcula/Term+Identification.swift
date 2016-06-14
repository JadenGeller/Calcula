//
//  Lexiographic.swift
//  Calcula
//
//  Created by Jaden Geller on 5/22/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

extension Term: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        var names: [Binding : String] = [:]
        return prettyDescription(withExistingNames: &names)
    }
    
    public var debugDescription: String {
        return description(naming: { String($0) })
    }
    
    public func prettyDescription(inout withExistingNames names: [Binding : String]) -> String {
        var identifierGenerator = LexiographicGenerator()
        return description(naming: { binding in
            if let name = names[binding] {
                return name
            } else {
                let name = identifierGenerator.next()!
                names[binding] = name
                return name
            }
        })
    }
    
    private var isTightlyBound: Bool {
        switch self {
        case .variable, .constant:
            return true
        case .application, .lambda:
            return false
        }
    }
    
    public func description(naming name: (Binding -> String)) -> String {
        switch self {
        case .constant(let value):
            return String(value)
        case .variable(let binding):
            return name(binding)
        case .lambda(let argument, let body):
            return "λ" + name(argument) + "." + body.description(naming: name)
        case .application(let lhs, let rhs):
            switch (lhs, rhs) {
            case (.variable, let r) where r.isTightlyBound:
                return lhs.description(naming: name) + " " + rhs.description(naming: name)
            case (.application, let r) where r.isTightlyBound:
                return lhs.description(naming: name) + " " + rhs.description(naming: name)
            case (.variable, _), (.application, _):
                return lhs.description(naming: name) + "(" + rhs.description(naming: name) + ")"
            case (.lambda, .variable):
                return "(" + lhs.description(naming: name) + ")" + rhs.description(naming: name)
            default:
                return "(" + lhs.description(naming: name) + ")(" + rhs.description(naming: name) + ")"
            }
        }
    }
}

public struct LexiographicSequence: SequenceType {
    public init() { }
    
    public func generate() -> LexiographicGenerator {
        return LexiographicGenerator()
    }
}

public struct LexiographicGenerator: GeneratorType {
    public init() { }
    
    private var state = IdentifierGenerator(elements: (97...122).map{ Character(UnicodeScalar($0)) })
    public mutating func next() -> String? {
        return state.next().map{ String($0) }
    }
}

public struct IdentifierSequence<Element>: SequenceType {
    private let elements: [Element]
    public init<C: CollectionType where C.Generator.Element == Element>(elements: C) {
        self.elements = Array(elements)
    }
    
    public func generate() -> IdentifierGenerator<Element> {
        return IdentifierGenerator(elements: elements)
    }
}

public struct IdentifierGenerator<Element>: GeneratorType {
    private let elements: [Element]
    public init<C: CollectionType where C.Generator.Element == Element>(elements: C) {
        self.elements = Array(elements)
    }
    
    private var state: [[Element]] = [[]]
    private var indexer: IndexingGenerator<[[Element]]> = [].generate()
    public mutating func next() -> [Element]? {
        if let next = indexer.next() {
            return next
        } else {
            state = elements.flatMap { e in self.state.map { [e] + $0 } }
            indexer = state.generate()
            return indexer.next()
        }
    }
}
