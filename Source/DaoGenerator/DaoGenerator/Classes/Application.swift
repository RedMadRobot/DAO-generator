//
//  Application.swift
//  DaoGenerator
//
//  Created by Andrei Rozhkov on 14/06/16.
//  Copyright © 2016 Redmadrobot. All rights reserved.
//

import Foundation


/**
 ### class Application
 
 Assumed **main.swift** will call:
 ```
 exit(Application().run())
 ```
 - precondition: Model classes folder should be passed as input.
 
 - postcondition: Result: DataBase model classes files and Translator implemetation.
 - note: Model classes should include annotations.
 - seealso: main.swift
 */


class Application {

    /**
     Run arguments.
     */
    let arguments: [String]

    
    // MARK: - Public

    init() {
        arguments = CommandLine.arguments
    }

    
    func run() -> Int32 {
        if arguments.contains("-help") || arguments.contains("--help") {
            printHelp()
            return 0
        }

        let projectName: String = valueForArgument(argument: "-project_name", defaultValue: "GEN")
        let inputFilesFolder: String = valueForArgument(argument: "-input", defaultValue: ".")
        let outputModelFolder: String = valueForArgument(argument: "-output_model", defaultValue: ".")
        let outputTranslatorFolder: String = valueForArgument(argument: "-output_translator", defaultValue: ".")
        let debugMode: Bool = arguments.contains("-debug")

        if debugMode {
            printArguments(arguments: arguments)
        }

        let inputFilePaths: [String] = collectInputFilesAtDirectory(
                directory: inputFilesFolder,
                fileExtension: ".swift",
                debugMode: debugMode)

        let klasses: [Klass] = readKlasses(
                filePathList: inputFilePaths,
                debugMode: debugMode)

        let modelsWritten: Int = tryWriteModels(
                forKlasses: klasses,
                outputFolder: outputModelFolder,
                projectName: projectName,
                debugMode: debugMode)

        let translatorsWritten: Int = tryWriteTranslators(
                forKlasses: klasses,
                outputFolder: outputTranslatorFolder,
                projectName: projectName,
                debugMode: debugMode)

        print("DBModels written: " + String(modelsWritten))
        print("Translators written: " + String(translatorsWritten))

        return 0
    }

}


private extension Application {

    func printHelp() {
        print("Accepted arguments:")
        print("")
        print("-input <directory>")
        print("Path to the folder, where header files to be processed are stored.")
        print("If not set, current working directory is used by default.")
        print("")
        print("-output_model <directory>")
        print("Path to the folder, where generated model files should be placed.")
        print("If not set, current working directory is used by default")
        print("-output_translator <directory>")
        print("Path to the folder, where generated translator files should be placed.")
        print("If not set, current working directory is used by default")
        print("")
        print("-project_name <name>")
        print("Project name to be used in generated files.")
        print("If not set, \"GEN\" is used as a default project name.")
        print("")
        print("-debug")
        print("Forces generator to print names of analyzed input files and generated translators.")
    }

    
    func valueForArgument(argument: String, defaultValue: String) -> String {
        guard let index: Int = arguments.index(of: argument)
        else {
            return defaultValue
        }

        return arguments.count > index + 1 ? arguments[index + 1] : defaultValue
    }

    
    func printArguments(arguments: [String]) {
        print("Arguments: " + arguments.reduce("", { (string: String,
                                                      argument: String) -> String in
            return string + argument + " "}))
    }

    
    func collectInputFilesAtDirectory(
            directory: String,
            fileExtension: String,
            debugMode: Bool) -> [String] {
        let filePaths: [String] = FileListFetcher().fileListInFolder(folder: directory)

        return filePaths.filter { (filePath: String) -> Bool in
            if debugMode {
                print("Found input item: \(filePath)")
            }

            return filePath.hasSuffix(fileExtension)
        }
    }

    func readKlasses(filePathList paths: [String], debugMode: Bool) -> [Klass] {
        return paths.flatMap({ (filePath: String) -> Klass? in
                    let filename: String = filePath.truncateUntilWord("/")

                    if debugMode {
                        print("Loading file " + filename)
                    }

                    let sourceCode: String = try! String(contentsOfFile: filePath)
                    let klass: Klass? = tryCompileSourceCode(
                            code: sourceCode,
                            filename: filename,
                            debugMode: debugMode)

                    return klass
                })
                .filter { (element: Klass) -> Bool in
                    let isModelClass: Bool = element.isModel
                    if debugMode && isModelClass {
                        print("Found model class " + element.name)
                    }
                    return isModelClass
                }
    }

    
    func tryCompileSourceCode(code: String, filename: String, debugMode: Bool) -> Klass? {
        var sourceCodeLines: [SourceCodeLine] = []

        for (index, line) in code.lines().enumerated() {
            sourceCodeLines.append(
                    SourceCodeLine(
                            absoluteFilePath: filename,
                            lineNumber: index,
                            line: line))
        }

        let sourceCodeFile: SourceCodeFile = SourceCodeFile(
                absoluteFilePath: filename,
                lines: sourceCodeLines)

        return tryCompileSourceCode(
                code: sourceCodeFile,
                filename: filename,
                debugMode: debugMode)
    }

    
    func tryCompileSourceCode(
            code: SourceCodeFile,
            filename: String,
            debugMode: Bool) -> Klass? {
        var klass: Klass? = nil

        do {
            klass = try Compiler(verbose: debugMode).compile(file: code)
        } catch let error as CompilerMessage {
            print(error)
        } catch {
            // ничего не делать
        }

        return klass
    }

    
    func tryWriteModels(
            forKlasses klasses: [Klass],
            outputFolder: String,
            projectName: String,
            debugMode: Bool) -> Int {
        let implementations: [Implementation] = klasses
                .flatMap { (k: Klass) -> Implementation? in
            do {
                return Implementation(
                        filePath: "DB\(k.name).swift",
                        sourceCode: try ModelImplementationWriter().writeImplementation(
                                klass: k,
                                klasses: klasses,
                                projectName: projectName)
                )
            } catch let error {
                print(error)
            }

            return nil
        }

        return tryWriteImplementations(
                implementations: implementations,
                outputFolder: outputFolder,
                projectName: projectName,
                debugMode: debugMode)
    }
    

    func tryWriteTranslators(
            forKlasses klasses: [Klass],
            outputFolder: String,
            projectName: String,
            debugMode: Bool) -> Int {
        let implementations: [Implementation] = klasses
                .flatMap { (k: Klass) -> Implementation? in
            do {
                return Implementation(
                        filePath: k.name + "DAOTranslator.swift",
                        sourceCode: try TranslatorImplementationWriter()
                                .writeImplementation(
                                        klass: k,
                                        klasses: klasses,
                                        projectName: projectName))
            } catch let error {
                print(error)
            }

            return nil
        }

        return tryWriteImplementations(
                implementations: implementations,
                outputFolder: outputFolder,
                projectName: projectName,
                debugMode: debugMode)
    }

    
    func tryWriteImplementations(
            implementations: [Implementation],
            outputFolder: String,
             projectName: String,
            debugMode: Bool) -> Int {
        let path: String
        if !outputFolder.hasSuffix("/") {
            path = outputFolder + "/"
        } else {
            path = outputFolder
        }

        return implementations.reduce(0, { (written: Int, i: Implementation) -> Int in
            do {
                try FileManager.default.createDirectory(
                        atPath: path,
                        withIntermediateDirectories: true,
                        attributes: nil)
                let writer = CheckedFileWriter(atomic: false)
                try writer.write(string: i.sourceCode, toFile: path + i.filePath)
            } catch {
                return written
            }

            return written + 1
        })
    }

}
