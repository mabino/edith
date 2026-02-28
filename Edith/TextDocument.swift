//
//  TextDocument.swift
//  Edith
//

import SwiftUI
import UniformTypeIdentifiers

struct TextDocument: FileDocument {
    var text: String
    var encoding: TextEncodingOption
    var lineEnding: LineEnding
    
    static var readableContentTypes: [UTType] { [.plainText] }
    
    init(text: String = "") {
        self.text = text
        // Default encoding from settings
        let encodingIndex = UserDefaults.standard.integer(forKey: "defaultTextEncoding")
        self.encoding = TextEncodingOption(rawValue: encodingIndex) ?? .utf8
        self.lineEnding = LineEnding.detect(in: text)
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        // Try to decode with the default encoding from settings
        let encodingIndex = UserDefaults.standard.integer(forKey: "defaultTextEncoding")
        let defaultEncoding = TextEncodingOption(rawValue: encodingIndex) ?? .utf8
        
        if let string = String(data: data, encoding: defaultEncoding.stringEncoding) {
            text = string
            encoding = defaultEncoding
        } else if let string = String(data: data, encoding: .utf8) {
            text = string
            encoding = .utf8
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        // Detect line ending from content
        lineEnding = LineEnding.detect(in: text)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Normalize line endings before saving
        var outputText = text
        
        // First normalize all line endings to LF
        outputText = outputText.replacingOccurrences(of: "\r\n", with: "\n")
        outputText = outputText.replacingOccurrences(of: "\r", with: "\n")
        
        // Then convert to the target line ending
        if lineEnding == .crlf {
            outputText = outputText.replacingOccurrences(of: "\n", with: "\r\n")
        } else if lineEnding == .cr {
            outputText = outputText.replacingOccurrences(of: "\n", with: "\r")
        }
        
        guard let data = outputText.data(using: encoding.stringEncoding) ?? outputText.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
