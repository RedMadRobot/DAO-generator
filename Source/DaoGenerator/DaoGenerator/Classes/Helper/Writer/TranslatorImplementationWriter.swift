//
//  TranslatorImplementationWriter.swift
//  DaoGenerator
//
//  Created by Andrei Rozhkov on 14/06/16.
//  Copyright © 2016 Redmadrobot. All rights reserved.
//

import Foundation


/**
 Translator Implementation Writer.
 */


class TranslatorImplementationWriter {

    // MARK: - Public

    /// Write Implementation
    ///
    /// - Parameters:
    ///   - klass: Klass to write
    ///   - klasses: All klasses
    ///   - projectName: name of project
    /// - Returns: content of file
    /// - Throws: exception
    internal func writeImplementation(
            klass: Klass,
            klasses: [Klass],
            projectName: String) throws -> String {
        let head: String = ""
                .addLine("//")
                .addLine("//  \(klass.name)DAOTranslator.swift")
                .addLine("//  \(projectName)")
                .addLine("//")
                .addLine("//  Created by Code Generator")
                .addLine("//  Copyright (c) 2016 RedMadRobot LLC. All rights reserved.")
                .addLine("//")
                .addBlankLine()

        let headImports: String = head
                .addLine("import DAO")
                .addBlankLine()
                .addBlankLine()

        let headImportsTranslatorObject: String = headImports
                .addLine("final class \(klass.name)DAOTranslator: RealmTranslator<\(klass.name), DB\(klass.name)> {")
                .addBlankLine()

        let inheritedProperties: [Property] = fetchInheritedProperties(
                classSpecification: klass,
                availableClassSpecifications: klasses)
                .filter({ $0.realm() })

        let toEntry = ""
                .addLine("override func fill(_ entity: \(klass.name), fromEntry: DB\(klass.name)) {")
                .addLine("entity.entityId = fromEntry.entryId".indent())
                .append(try self.entryLines(
                                klasses: klasses,
                                properties: inheritedProperties + klass.properties
                                .filter {
                            $0.realm()
                        })
                        .indent())
                .addLine("}")
                .addBlankLine()
                .indent()

        let toEntity = ""
                .addLine("override func fill(_ entry: DB\(klass.name), fromEntity: \(klass.name)) {")
                .addLine("if entry.entryId != fromEntity.entityId {".indent())
                .addLine("entry.entryId = fromEntity.entityId".indent(tabCount: 2))
                .addLine("}".indent())
                .append(try self.entityLines(
                                klasses: klasses,
                                properties: klass.properties
                                .filter {
                            $0.realm()
                        })
                        .indent())
                .addLine("}")
                .addBlankLine()
                .indent()

        return headImportsTranslatorObject
                .append(toEntry)
                .append(toEntity)
                .addLine("}")
    }
}


private extension TranslatorImplementationWriter {

    // fill entity
    func entryLines(klasses: [Klass], properties: [Property]) throws -> String {
        return properties.reduce("") { (line: String, p: Property) -> String in
            switch p.type {
            case .OptionalType(wrapped: .ObjectType(let typename)):
                return line
                    .addLine("if let entry = fromEntry.\(p.name) {")
                    .addLine("let \(p.name) = entity.\(p.name) ?? \(typename)()".indent())
                    .addLine("\(typename)DAOTranslator().fill(\(p.name), fromEntry: entry)".indent())
                    .addLine("entity.\(p.name) = \(p.name)".indent())
                    .addLine("}")
            case .OptionalType(wrapped: .BoolType),
                 .OptionalType(wrapped: .IntType),
                 .OptionalType(wrapped: .DoubleType),
                 .OptionalType(wrapped: .FloatType):
                return line
                    .addLine("entity.\(p.name) = fromEntry.\(p.name).value")
            case .OptionalType(wrapped: .ArrayType(item: let typename)):
                switch typename {
                case .ObjectType(name: let name):
                    return line
                        .addLine("entity.\(p.name) = fromEntry.\(p.name).map { _ in \(name)() }")
                        .addLine("if !fromEntry.\(p.name).isEmpty {")
                        .addLine("\(typename)DAOTranslator().fill(&entity.\(p.name)!, fromEntries: fromEntry.\(p.name))".indent())
                        .addLine("}")
                default:
                    return line
                        .addLine("entity.\(p.name) = fromEntry.\(p.name).map { $0.value }")
                }
            default:
                switch p.type {
                // Relationship
                case .ObjectType(let typename):
                    return line
                        .addLine("if let entry = fromEntry.\(p.name) {")
                        .addLine("\(typename)DAOTranslator().fill(entity.\(p.name), fromEntry: entry)".indent())
                        .addLine("}")
                // Collection
                case .ArrayType(let objectType):
                    switch objectType {
                    case .ObjectType(let typename):
                        return line
                            .addLine("\(typename)DAOTranslator().fill(&entity.\(p.name), fromEntries: fromEntry.\(p.name))")
                    case .ArrayType, .MapType:
                        fatalError()
                    default:
                        return line
                            .addLine("// FIX ME: Добавить работу с массивами простых типов для \(p.name)")
                    }
                // Свойство
                default:
                    return line
                        .addLine("entity.\(p.name) = fromEntry.\(p.name)")
                }
            }
        }
    }

    // fill entry
    func entityLines(klasses: [Klass], properties: [Property]) throws -> String {
        return properties.reduce("") { (line: String, p: Property) -> String in
            switch p.type {
            case .OptionalType(wrapped: .ObjectType(let typename)):
                return line
                    .addLine("if let entity = fromEntity.\(p.name) {")
                    .addLine("let \(p.name) = entry.\(p.name) ?? DB\(typename)()".indent())
                    .addLine("\(typename)DAOTranslator().fill(\(p.name), fromEntity: entity)".indent())
                    .addLine("entry.\(p.name) = \(p.name)".indent())
                    .addLine("}")
            case .OptionalType(wrapped: .BoolType),
                 .OptionalType(wrapped: .IntType),
                 .OptionalType(wrapped: .DoubleType),
                 .OptionalType(wrapped: .FloatType):
                return line
                    .addLine("entry.\(p.name).value = fromEntity.\(p.name)")
            case .OptionalType(wrapped: .ArrayType(item: let t)):
                switch t {
                case .ObjectType(name: let name):
                    return line
                        .addLine("if fromEntity.\(p.name)?.isEmpty == false {")
                        .addLine("\(name)DAOTranslator().fill(entry.\(p.name), fromEntities: fromEntity.\(p.name)!)".indent())
                        .addLine("} else {")
                        .addLine("entry.\(p.name).removeAll()".indent())
                        .addLine("}")
                case .StringType, .IntType, .DateType, .DoubleType, .FloatType, .BoolType, .DataType:
                    let type = typeDescription(t)
                    return line
                        .addLine("entry.\(p.name).removeAll()")
                        .addLine("if let \(p.name) = fromEntity.\(p.name)?.map { \(type)(val: $0) } {")
                        .addLine("entry.\(p.name).append(objectsIn: \(p.name))".indent())
                        .addLine("}")
                default:
                    return line
                        .addLine("TODO")
                }
            // Relationship
            case .ObjectType(let typename):
                return line
                    .addLine("let \(p.name) = entry.\(p.name) ?? DB\(typename)()")
                    .addLine("\(typename)DAOTranslator().fill(\(p.name), fromEntity: fromEntity.\(p.name))")
                    .addLine("entry.\(p.name) = \(p.name)")
            // Collection
            case .ArrayType(let objectType):
                switch objectType {
                case .StringType, .IntType, .DateType, .DoubleType, .FloatType, .BoolType, .DataType:
                    let type = typeDescription(objectType)
                    return line
                        .addLine("entry.\(p.name).removeAll()")
                        .addLine("let \(p.name) = fromEntity.\(p.name).map { \(type)(val: $0) }")
                        .addLine("entry.\(p.name).append(objectsIn: \(p.name))")
                case .ObjectType(let typename):
                    return line
                        .addLine("if !fromEntity.\(p.name).isEmpty {")
                        .addLine("\(typename)DAOTranslator().fill(entry.\(p.name), fromEntities: fromEntity.\(p.name))".indent())
                        .addLine("} else {")
                        .addLine("entry.\(p.name).removeAll()".indent())
                        .addLine("}")
                default:
                    fatalError()
                }
                // Property
            default:
                return line
                    .addLine("entry.\(p.name) = fromEntity.\(p.name)")
            }
        }
    }

    func fetchInheritedProperties(
            classSpecification: Klass,
            availableClassSpecifications: [Klass]) -> [Property] {
        return availableClassSpecifications.reduce([], { (properties: [Property],
                                                          c: Klass) -> [Property] in
            if classSpecification.parents.contains(c.name) {
                return properties + c.properties + fetchInheritedProperties(
                        classSpecification: c,
                        availableClassSpecifications: availableClassSpecifications)
            }

            return properties
        })
    }

    private func typeDescription(_ type: Typê) -> String {
        switch type {
        case .StringType:
            return "RLMString"
        case .DataType:
            return "RLMData"
        case .IntType:
            return "RLMInteger"
        case .DateType:
            return "RLMDate"
        case .DoubleType:
            return "RLMDouble"
        case .FloatType:
            return "RLMFloat"
        case .BoolType:
            return "RLMBool"
        default:
            return "TODO"
        }
    }
    
}
