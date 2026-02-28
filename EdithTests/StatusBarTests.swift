//
//  StatusBarTests.swift
//  EdithTests
//

import XCTest
@testable import Edith

final class StatusBarTests: XCTestCase {
    
    // MARK: - Line Ending Detection Tests
    
    func testLineEndingDetectionUnix() {
        let text = "Line 1\nLine 2\nLine 3"
        let detected = LineEnding.detect(in: text)
        XCTAssertEqual(detected, .lf)
    }
    
    func testLineEndingDetectionWindows() {
        let text = "Line 1\r\nLine 2\r\nLine 3"
        let detected = LineEnding.detect(in: text)
        XCTAssertEqual(detected, .crlf)
    }
    
    func testLineEndingDetectionLegacyMac() {
        let text = "Line 1\rLine 2\rLine 3"
        let detected = LineEnding.detect(in: text)
        XCTAssertEqual(detected, .cr)
    }
    
    func testLineEndingDetectionEmpty() {
        let text = ""
        let detected = LineEnding.detect(in: text)
        XCTAssertEqual(detected, .lf) // Default to Unix
    }
    
    func testLineEndingDetectionNoLineEndings() {
        let text = "Single line without newline"
        let detected = LineEnding.detect(in: text)
        XCTAssertEqual(detected, .lf) // Default to Unix
    }
    
    // MARK: - Line Ending Properties
    
    func testLineEndingDescriptions() {
        XCTAssertEqual(LineEnding.lf.description, "Unix (LF)")
        XCTAssertEqual(LineEnding.cr.description, "Legacy Mac (CR)")
        XCTAssertEqual(LineEnding.crlf.description, "Windows (CRLF)")
    }
    
    func testLineEndingShortDescriptions() {
        XCTAssertEqual(LineEnding.lf.shortDescription, "LF")
        XCTAssertEqual(LineEnding.cr.shortDescription, "CR")
        XCTAssertEqual(LineEnding.crlf.shortDescription, "CRLF")
    }
    
    func testLineEndingCharacters() {
        XCTAssertEqual(LineEnding.lf.characters, "\n")
        XCTAssertEqual(LineEnding.cr.characters, "\r")
        XCTAssertEqual(LineEnding.crlf.characters, "\r\n")
    }
    
    // MARK: - Cursor Position Tests
    
    func testCursorPositionAtStart() {
        let text = "Hello, World!"
        let position = CursorPosition.calculate(for: text, at: 0)
        XCTAssertEqual(position.line, 1)
        XCTAssertEqual(position.column, 1)
    }
    
    func testCursorPositionMiddleOfLine() {
        let text = "Hello, World!"
        let position = CursorPosition.calculate(for: text, at: 7)
        XCTAssertEqual(position.line, 1)
        XCTAssertEqual(position.column, 8)
    }
    
    func testCursorPositionEndOfLine() {
        let text = "Hello, World!"
        let position = CursorPosition.calculate(for: text, at: 13)
        XCTAssertEqual(position.line, 1)
        XCTAssertEqual(position.column, 14)
    }
    
    func testCursorPositionSecondLine() {
        let text = "Line 1\nLine 2"
        let position = CursorPosition.calculate(for: text, at: 7) // Start of "Line 2"
        XCTAssertEqual(position.line, 2)
        XCTAssertEqual(position.column, 1)
    }
    
    func testCursorPositionMiddleOfSecondLine() {
        let text = "Line 1\nLine 2"
        let position = CursorPosition.calculate(for: text, at: 10) // "e 2"
        XCTAssertEqual(position.line, 2)
        XCTAssertEqual(position.column, 4)
    }
    
    func testCursorPositionMultipleLines() {
        let text = "Line 1\nLine 2\nLine 3"
        let position = CursorPosition.calculate(for: text, at: 14) // Start of "Line 3"
        XCTAssertEqual(position.line, 3)
        XCTAssertEqual(position.column, 1)
    }
    
    func testCursorPositionEmptyText() {
        let text = ""
        let position = CursorPosition.calculate(for: text, at: 0)
        XCTAssertEqual(position.line, 1)
        XCTAssertEqual(position.column, 1)
    }
    
    func testCursorPositionNegativeIndex() {
        let text = "Hello"
        let position = CursorPosition.calculate(for: text, at: -5)
        XCTAssertEqual(position.line, 1)
        XCTAssertEqual(position.column, 1)
    }
    
    func testCursorPositionBeyondEnd() {
        let text = "Hello"
        let position = CursorPosition.calculate(for: text, at: 100)
        XCTAssertEqual(position.line, 1)
        XCTAssertEqual(position.column, 6) // Clamped to text.count
    }
    
    // MARK: - Settings Tests
    
    func testShowStatusBarDefaultValue() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "showStatusBar")
        
        let settingsManager = SettingsManager()
        XCTAssertTrue(settingsManager.showStatusBar)
    }
    
    // MARK: - Text Document Properties
    
    func testTextDocumentHasEncoding() {
        let doc = TextDocument(text: "Test")
        XCTAssertNotNil(doc.encoding)
    }
    
    func testTextDocumentHasLineEnding() {
        let doc = TextDocument(text: "Test")
        XCTAssertNotNil(doc.lineEnding)
    }
    
    func testTextDocumentDetectsLineEnding() {
        var doc = TextDocument(text: "Line 1\r\nLine 2")
        // Line ending should be detected on init
        XCTAssertEqual(doc.lineEnding, .crlf)
    }
}
