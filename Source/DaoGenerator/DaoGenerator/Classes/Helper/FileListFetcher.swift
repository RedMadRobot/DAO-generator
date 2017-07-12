//
//  FileListFetcher.swift
//  Generator
//
//  Created by Egor Taflanidi on 18.01.16.
//  Copyright © 2016 Egor Taflanidi. All rights reserved.
//

import Foundation


/// Fetches files inside input folder
class FileListFetcher {
    
    internal func fileListInFolder(folder: String) -> [String] {
        let folderPath: String = absolutePath(path: folder)
        
        let filesAtFolder:   [String] = self.filesAtFolder(folderPath)
        let foldersAtFolder: [String] = self.foldersAtFolder(folderPath)
        
        let filesInSubfolders: [String] = foldersAtFolder
                .reduce([]) { (items: [String], folder: String) -> [String] in
            return items + fileListInFolder(folder: folder)
        }
        
        return filesAtFolder + filesInSubfolders
    }
    
    
    private func absolutePath(path: String = "") -> String {
        let currentDirectory: String = FileManager.default.currentDirectoryPath
        
        print("WORKING DIRECTORY: " + currentDirectory)
        
        if path.isEmpty {
            return currentDirectory
        } else {
            if path.hasPrefix(".") {
                return currentDirectory + "/" + path
            } else {
                return path
            }
        }
    }
    
    
    private func filesAtFolder(_ folder: String) -> [String] {
        return itemsAtFolder(folderPath: folder, directories: false)
    }
    
    
    private func foldersAtFolder(_ folder: String) -> [String] {
        return itemsAtFolder(folderPath: folder, directories: true)
    }
    
    
    private func itemsAtFolder(folderPath: String, directories: Bool) -> [String] {
        let folderContents: [String]
        let fileManager: FileManager = FileManager()
        do {
            folderContents = try fileManager.contentsOfDirectory(atPath: folderPath)
        } catch {
            return []
        }
        
        return folderContents.flatMap { (path: String) -> String? in
            var isFolder: ObjCBool = ObjCBool(false)
            let fullPath: String   = folderPath + "/" + path
            
            fileManager.fileExists(atPath: fullPath, isDirectory: &isFolder)
            if directories == isFolder.boolValue {
                return fullPath
            }
            
            return nil
        }
    }
    
}
