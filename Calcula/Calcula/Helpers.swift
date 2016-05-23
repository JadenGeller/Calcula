//
//  Helpers.swift
//  Calcula
//
//  Created by Jaden Geller on 5/22/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

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
