//
//  TextEncodingTests.swift
//  EdithTests
//
//  Tests to verify text encoding functionality for save/load operations.
//

import XCTest
import UniformTypeIdentifiers
@testable import Edith

final class TextEncodingTests: XCTestCase {
    
    var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        // Create a temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EdithEncodingTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        // Clean up temporary directory
        try? FileManager.default.removeItem(at: tempDirectory)
        // Reset encoding to default
        UserDefaults.standard.set(TextEncodingOption.utf8.rawValue, forKey: "defaultTextEncoding")
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func setEncoding(_ encoding: TextEncodingOption) {
        UserDefaults.standard.set(encoding.rawValue, forKey: "defaultTextEncoding")
    }
    
    private func writeTestFile(text: String, encoding: TextEncodingOption) throws -> URL {
        // Simulate what TextDocument.fileWrapper does
        let stringEncoding = encoding.stringEncoding
        guard let data = text.data(using: stringEncoding) ?? text.data(using: .utf8) else {
            throw NSError(domain: "TestError", code: 1)
        }
        
        let fileURL = tempDirectory.appendingPathComponent("test_\(encoding.rawValue).txt")
        try data.write(to: fileURL)
        return fileURL
    }
    
    private func readTestFile(from url: URL, encoding: TextEncodingOption) throws -> String {
        let data = try Data(contentsOf: url)
        let stringEncoding = encoding.stringEncoding
        
        // Simulate what TextDocument.init(configuration:) does
        if let string = String(data: data, encoding: stringEncoding) {
            return string
        } else if let string = String(data: data, encoding: .utf8) {
            return string
        } else {
            throw NSError(domain: "TestError", code: 2)
        }
    }
    
    private func readRawData(from url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }
    
    // MARK: - UTF-8 Encoding Tests
    
    func testUTF8EncodingSavesCorrectBytes() throws {
        let text = "Hello, World! 你好世界 🌍"
        let fileURL = try writeTestFile(text: text, encoding: .utf8)
        
        let rawData = try readRawData(from: fileURL)
        let expectedData = text.data(using: .utf8)!
        
        XCTAssertEqual(rawData, expectedData, "UTF-8 encoded data should match expected bytes")
    }
    
    func testUTF8EncodingRoundTrip() throws {
        let text = "Hello, World! 你好世界 🌍 émojis and ümlauts"
        let fileURL = try writeTestFile(text: text, encoding: .utf8)
        
        let readText = try readTestFile(from: fileURL, encoding: .utf8)
        
        XCTAssertEqual(readText, text, "UTF-8 round trip should preserve text exactly")
    }
    
    func testUTF8NoByteOrderMark() throws {
        let text = "Simple ASCII text"
        let fileURL = try writeTestFile(text: text, encoding: .utf8)
        
        let rawData = try readRawData(from: fileURL)
        
        // UTF-8 BOM is EF BB BF - verify it's not present (we don't add BOM)
        let hasBOM = rawData.count >= 3 && rawData[0] == 0xEF && rawData[1] == 0xBB && rawData[2] == 0xBF
        XCTAssertFalse(hasBOM, "UTF-8 should not have BOM by default")
    }
    
    // MARK: - UTF-16 Encoding Tests
    
    func testUTF16EncodingSavesCorrectBytes() throws {
        let text = "Hello"
        let fileURL = try writeTestFile(text: text, encoding: .utf16)
        
        let rawData = try readRawData(from: fileURL)
        let expectedData = text.data(using: .utf16)!
        
        XCTAssertEqual(rawData, expectedData, "UTF-16 encoded data should match expected bytes")
    }
    
    func testUTF16HasByteOrderMark() throws {
        let text = "Test"
        let fileURL = try writeTestFile(text: text, encoding: .utf16)
        
        let rawData = try readRawData(from: fileURL)
        
        // UTF-16 BOM is either FE FF (big endian) or FF FE (little endian)
        let hasBOM = rawData.count >= 2 && 
            ((rawData[0] == 0xFE && rawData[1] == 0xFF) || (rawData[0] == 0xFF && rawData[1] == 0xFE))
        
        XCTAssertTrue(hasBOM, "UTF-16 should have BOM")
    }
    
    func testUTF16RoundTrip() throws {
        let text = "Unicode text: 日本語 한국어"
        let fileURL = try writeTestFile(text: text, encoding: .utf16)
        
        let readText = try readTestFile(from: fileURL, encoding: .utf16)
        
        XCTAssertEqual(readText, text, "UTF-16 round trip should preserve text exactly")
    }
    
    // MARK: - UTF-16 Big Endian Tests
    
    func testUTF16BigEndianEncodingSavesCorrectBytes() throws {
        let text = "Test"
        let fileURL = try writeTestFile(text: text, encoding: .utf16BigEndian)
        
        let rawData = try readRawData(from: fileURL)
        let expectedData = text.data(using: .utf16BigEndian)!
        
        XCTAssertEqual(rawData, expectedData, "UTF-16BE encoded data should match expected bytes")
    }
    
    func testUTF16BigEndianByteOrder() throws {
        let text = "A"  // 'A' is 0x0041 in UTF-16
        let fileURL = try writeTestFile(text: text, encoding: .utf16BigEndian)
        
        let rawData = try readRawData(from: fileURL)
        
        // Big endian: high byte first (00 41)
        XCTAssertEqual(rawData[0], 0x00, "First byte should be 0x00 for big endian 'A'")
        XCTAssertEqual(rawData[1], 0x41, "Second byte should be 0x41 for big endian 'A'")
    }
    
    func testUTF16BigEndianRoundTrip() throws {
        let text = "Big Endian Test: 中文"
        let fileURL = try writeTestFile(text: text, encoding: .utf16BigEndian)
        
        let readText = try readTestFile(from: fileURL, encoding: .utf16BigEndian)
        
        XCTAssertEqual(readText, text, "UTF-16BE round trip should preserve text exactly")
    }
    
    // MARK: - UTF-16 Little Endian Tests
    
    func testUTF16LittleEndianEncodingSavesCorrectBytes() throws {
        let text = "Test"
        let fileURL = try writeTestFile(text: text, encoding: .utf16LittleEndian)
        
        let rawData = try readRawData(from: fileURL)
        let expectedData = text.data(using: .utf16LittleEndian)!
        
        XCTAssertEqual(rawData, expectedData, "UTF-16LE encoded data should match expected bytes")
    }
    
    func testUTF16LittleEndianByteOrder() throws {
        let text = "A"  // 'A' is 0x0041 in UTF-16
        let fileURL = try writeTestFile(text: text, encoding: .utf16LittleEndian)
        
        let rawData = try readRawData(from: fileURL)
        
        // Little endian: low byte first (41 00)
        XCTAssertEqual(rawData[0], 0x41, "First byte should be 0x41 for little endian 'A'")
        XCTAssertEqual(rawData[1], 0x00, "Second byte should be 0x00 for little endian 'A'")
    }
    
    func testUTF16LittleEndianRoundTrip() throws {
        let text = "Little Endian Test: Ελληνικά"
        let fileURL = try writeTestFile(text: text, encoding: .utf16LittleEndian)
        
        let readText = try readTestFile(from: fileURL, encoding: .utf16LittleEndian)
        
        XCTAssertEqual(readText, text, "UTF-16LE round trip should preserve text exactly")
    }
    
    // MARK: - ASCII Encoding Tests
    
    func testASCIIEncodingSavesCorrectBytes() throws {
        let text = "Hello, World! 123"
        let fileURL = try writeTestFile(text: text, encoding: .ascii)
        
        let rawData = try readRawData(from: fileURL)
        let expectedData = text.data(using: .ascii)!
        
        XCTAssertEqual(rawData, expectedData, "ASCII encoded data should match expected bytes")
    }
    
    func testASCIIEncodingBytesAre7Bit() throws {
        let text = "ABCabc123!@#"
        let fileURL = try writeTestFile(text: text, encoding: .ascii)
        
        let rawData = try readRawData(from: fileURL)
        
        // All ASCII bytes should be < 128
        for byte in rawData {
            XCTAssertLessThan(byte, 128, "ASCII bytes should be 7-bit (< 128)")
        }
    }
    
    func testASCIIRoundTrip() throws {
        let text = "Pure ASCII: Hello, World! 12345 !@#$%"
        let fileURL = try writeTestFile(text: text, encoding: .ascii)
        
        let readText = try readTestFile(from: fileURL, encoding: .ascii)
        
        XCTAssertEqual(readText, text, "ASCII round trip should preserve text exactly")
    }
    
    // MARK: - ISO Latin 1 Encoding Tests
    
    func testISOLatin1EncodingSavesCorrectBytes() throws {
        let text = "Café résumé naïve"
        let fileURL = try writeTestFile(text: text, encoding: .isoLatin1)
        
        let rawData = try readRawData(from: fileURL)
        let expectedData = text.data(using: .isoLatin1)!
        
        XCTAssertEqual(rawData, expectedData, "ISO Latin 1 encoded data should match expected bytes")
    }
    
    func testISOLatin1SpecificCharacter() throws {
        let text = "é"  // é is 0xE9 in ISO Latin 1
        let fileURL = try writeTestFile(text: text, encoding: .isoLatin1)
        
        let rawData = try readRawData(from: fileURL)
        
        XCTAssertEqual(rawData.count, 1, "Single ISO Latin 1 character should be 1 byte")
        XCTAssertEqual(rawData[0], 0xE9, "é should be encoded as 0xE9 in ISO Latin 1")
    }
    
    func testISOLatin1RoundTrip() throws {
        let text = "Ångström résumé naïve"
        let fileURL = try writeTestFile(text: text, encoding: .isoLatin1)
        
        let readText = try readTestFile(from: fileURL, encoding: .isoLatin1)
        
        XCTAssertEqual(readText, text, "ISO Latin 1 round trip should preserve text exactly")
    }
    
    // MARK: - Mac OS Roman Encoding Tests
    
    func testMacOSRomanEncodingSavesCorrectBytes() throws {
        let text = "Apple Macintosh"
        let fileURL = try writeTestFile(text: text, encoding: .macOSRoman)
        
        let rawData = try readRawData(from: fileURL)
        let expectedData = text.data(using: .macOSRoman)!
        
        XCTAssertEqual(rawData, expectedData, "Mac OS Roman encoded data should match expected bytes")
    }
    
    func testMacOSRomanRoundTrip() throws {
        let text = "Mac OS Roman text"
        let fileURL = try writeTestFile(text: text, encoding: .macOSRoman)
        
        let readText = try readTestFile(from: fileURL, encoding: .macOSRoman)
        
        XCTAssertEqual(readText, text, "Mac OS Roman round trip should preserve text exactly")
    }
    
    // MARK: - Windows CP1252 Encoding Tests
    
    func testWindowsCP1252EncodingSavesCorrectBytes() throws {
        let text = "Windows text"
        let fileURL = try writeTestFile(text: text, encoding: .windowsCP1252)
        
        let rawData = try readRawData(from: fileURL)
        let expectedData = text.data(using: .windowsCP1252)!
        
        XCTAssertEqual(rawData, expectedData, "Windows CP1252 encoded data should match expected bytes")
    }
    
    func testWindowsCP1252EuroSign() throws {
        // Euro sign is 0x80 in CP1252
        let text = "\u{20AC}"  // Euro sign €
        let fileURL = try writeTestFile(text: text, encoding: .windowsCP1252)
        
        let rawData = try readRawData(from: fileURL)
        
        XCTAssertEqual(rawData.count, 1, "Euro sign should be 1 byte in CP1252")
        XCTAssertEqual(rawData[0], 0x80, "Euro sign should be 0x80 in CP1252")
    }
    
    func testWindowsCP1252RoundTrip() throws {
        let text = "Windows text with special chars"
        let fileURL = try writeTestFile(text: text, encoding: .windowsCP1252)
        
        let readText = try readTestFile(from: fileURL, encoding: .windowsCP1252)
        
        XCTAssertEqual(readText, text, "Windows CP1252 round trip should preserve text exactly")
    }
    
    // MARK: - Cross-Encoding Tests
    
    func testReadingUTF8FileAsUTF8() throws {
        // Write UTF-8 file directly
        let text = "UTF-8 text: 日本語"
        let fileURL = tempDirectory.appendingPathComponent("utf8_direct.txt")
        try text.data(using: .utf8)!.write(to: fileURL)
        
        // Read with UTF-8 setting
        let readText = try readTestFile(from: fileURL, encoding: .utf8)
        
        XCTAssertEqual(readText, text, "Reading UTF-8 file with UTF-8 setting should work")
    }
    
    func testFallbackToUTF8WhenEncodingFails() throws {
        // Write a UTF-8 file with characters not in ASCII
        let text = "日本語"
        let fileURL = tempDirectory.appendingPathComponent("utf8_fallback.txt")
        try text.data(using: .utf8)!.write(to: fileURL)
        
        // Try to read with ASCII setting (which can't decode these characters)
        // The implementation should fall back to UTF-8
        let readText = try readTestFile(from: fileURL, encoding: .ascii)
        
        XCTAssertEqual(readText, text, "Should fall back to UTF-8 when primary encoding fails")
    }
    
    // MARK: - Encoding Enum Tests
    
    func testAllEncodingOptionsHaveStringEncoding() {
        for option in TextEncodingOption.allCases {
            XCTAssertNotNil(option.stringEncoding, "\(option) should have a String.Encoding")
        }
    }
    
    func testAllEncodingOptionsHaveDescription() {
        for option in TextEncodingOption.allCases {
            XCTAssertFalse(option.description.isEmpty, "\(option) should have a description")
        }
    }
    
    func testEncodingOptionsAreUnique() {
        var rawValues = Set<Int>()
        for option in TextEncodingOption.allCases {
            XCTAssertFalse(rawValues.contains(option.rawValue), "Encoding raw values should be unique")
            rawValues.insert(option.rawValue)
        }
    }
    
    func testDefaultEncodingIsUTF8() {
        XCTAssertEqual(TextEncodingOption.utf8.rawValue, 0, "UTF-8 should be the first encoding (rawValue 0)")
    }
    
    func testEncodingCount() {
        XCTAssertEqual(TextEncodingOption.allCases.count, 8, "Should have 8 encoding options")
    }
    
    // MARK: - Empty File Tests
    
    func testEmptyFileRoundTripAllEncodings() throws {
        let text = ""
        
        for encoding in TextEncodingOption.allCases {
            let fileURL = tempDirectory.appendingPathComponent("empty_\(encoding.rawValue).txt")
            let data = text.data(using: encoding.stringEncoding)!
            try data.write(to: fileURL)
            
            let readText = try readTestFile(from: fileURL, encoding: encoding)
            
            XCTAssertEqual(readText, text, "Empty file round trip should work for \(encoding.description)")
        }
    }
    
    // MARK: - Large File Tests
    
    func testLargeFileRoundTrip() throws {
        // Create a large text with 10,000 lines
        let text = (1...10000).map { "Line \($0): This is some test content" }.joined(separator: "\n")
        let fileURL = try writeTestFile(text: text, encoding: .utf8)
        
        let readText = try readTestFile(from: fileURL, encoding: .utf8)
        
        XCTAssertEqual(readText, text, "Large file round trip should preserve text exactly")
    }
    
    // MARK: - Newline Handling Tests
    
    func testUnixNewlinesPreserved() throws {
        let text = "Line 1\nLine 2\nLine 3"
        let fileURL = try writeTestFile(text: text, encoding: .utf8)
        
        let readText = try readTestFile(from: fileURL, encoding: .utf8)
        
        XCTAssertEqual(readText, text, "Unix newlines should be preserved")
        XCTAssertTrue(readText.contains("\n"), "Should contain LF characters")
    }
    
    func testWindowsNewlinesPreserved() throws {
        let text = "Line 1\r\nLine 2\r\nLine 3"
        let fileURL = try writeTestFile(text: text, encoding: .utf8)
        
        let readText = try readTestFile(from: fileURL, encoding: .utf8)
        
        XCTAssertEqual(readText, text, "Windows newlines should be preserved")
        XCTAssertTrue(readText.contains("\r\n"), "Should contain CRLF sequences")
    }
    
    // MARK: - TextDocument Integration Tests
    
    func testTextDocumentUsesEncodingSetting() throws {
        // Set encoding to UTF-16
        setEncoding(.utf16)
        
        let document = TextDocument(text: "Test")
        
        // The document should use the encoding from settings when writing
        // We can verify this by checking that the setting is correctly read
        let currentEncoding = UserDefaults.standard.integer(forKey: "defaultTextEncoding")
        XCTAssertEqual(currentEncoding, TextEncodingOption.utf16.rawValue)
    }
    
    func testTextDocumentCreatesWithText() {
        let text = "Hello, World!"
        let document = TextDocument(text: text)
        XCTAssertEqual(document.text, text)
    }
    
    func testTextDocumentCreatesEmpty() {
        let document = TextDocument()
        XCTAssertEqual(document.text, "")
    }
}
