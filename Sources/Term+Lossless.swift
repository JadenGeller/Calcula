//
//  Term+Lossless.swift
//  Calcula
//
//  Created by Jaden Geller on 6/12/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

public enum ParseError: ErrorType {
    case expectedCharacter(Character)
    case expectedIdentifier
    case expectedEnd
}

extension Term {
    public init?(_ description: String) {
        do {
            self = try Term(parsing: description)
        } catch {
            return nil
        }
    }

    public init(parsing description: String) throws {
        var bindings: [String: Binding] = [:]
        self = try Term(parsing: description, withExistingBindings: &bindings)
    }

    public init(parsing description: String, inout withExistingBindings bindings: [String : Binding]) throws {
        var state = description.characters.generate()
        let term = try Term(term: &state, bindings: &bindings)
        guard state.peek() == nil else { throw ParseError.expectedEnd }
        self = term
    }
    
    private init(inout term state: IndexingGenerator<String.CharacterView>, inout bindings: [String : Binding]) throws {
        guard state.peek() != "λ" else {
            self = try Term(lambda: &state, bindings: &bindings)
            return
        }
        
        var terms: [Term] = []
        repeat {
            if state.peek() == "(" {
                terms.append(try Term(parenthesized: &state, bindings: &bindings))
            } else {
                terms.append(try Term(variable: &state, bindings: &bindings))
            }
            while state.peek() == " " { state.next() } // Skip whitespace
        } while state.peek() != nil && state.peek() != ")"
    
        self = terms.reduce(Term.application)!
    }
    
    private init(inout parenthesized state: IndexingGenerator<String.CharacterView>, inout bindings: [String : Binding]) throws {
        guard "(" == state.next() else { throw ParseError.expectedCharacter("(") }
        let term = try Term(term: &state, bindings: &bindings)
        guard ")" == state.next() else { throw ParseError.expectedCharacter(")") }
        self = term
    }
    
    private init(inout variable state: IndexingGenerator<String.CharacterView>, inout bindings: [String : Binding]) throws {
        let identifier: String = {
            var characters: [Character] = []
            while let character = state.peek() where "A"..."z" ~= character || "0"..."9" ~= character {
                state.next()
                characters.append(character)
            }
            return String(characters)
        }()
        guard identifier.characters.count > 0 else { throw ParseError.expectedIdentifier }
        let binding: Binding = {
            if let existing = bindings[identifier] { return existing }
            else {
                let new = Binding()
                bindings[identifier] = new
                return new
            }
        }()
        self = Term.variable(binding)
    }
    
    private init(inout lambda state: IndexingGenerator<String.CharacterView>, inout bindings: [String : Binding]) throws {
        guard state.next() == "λ" else { throw ParseError.expectedCharacter("λ") }
        guard case .variable(let binding) = try Term(variable: &state, bindings: &bindings) else { fatalError() }
        guard state.next() == "." else { throw ParseError.expectedCharacter(".") }
        let term = try Term(term: &state, bindings: &bindings)
        self = Term.lambda(binding, term)
    }
}

extension IndexingGenerator {
    private func peek() -> Generator.Element? {
        var copy = self
        return copy.next()
    }
}

extension SequenceType where SubSequence: SequenceType {
    private func reduce(@noescape combine: (Self.Generator.Element, Self.Generator.Element) throws -> Self.Generator.Element) rethrows -> Self.Generator.Element? {
        var generator = generate()
        var result = generator.next()
        while let next = generator.next() {
            result = try combine(result!, next)
        }
        return result
    }
}
