//
//  TextDocument.swift
//  Edith
//

import SwiftUI
import UniformTypeIdentifiers

struct TextDocument: FileDocument {
    var text: String
    
    static var readableContentTypes: [UTType] { [.plainText] }
    
    init(text: String = "") {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        // Try to decode with the default encoding from settings
        let encodingIndex = UserDefaults.standard.integer(forKey: "defaultTextEncoding")
        let stringEncoding = TextEncodingOption(rawValue: encodingIndex)?.stringEncoding ?? .utf8
        
        if let string = String(data: data, encoding: stringEncoding) {
            text = string
        } else if let string = String(data: data, encoding: .utf8) {
            text = string
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encodingIndex = UserDefaults.standard.integer(forKey: "defaultTextEncoding")
        let stringEncoding = TextEncodingOption(rawValue: encodingIndex)?.stringEncoding ?? .utf8
        
        guard let data = text.data(using: stringEncoding) ?? text.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
