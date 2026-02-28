//
//  SessionRestoreTests.swift
//  EdithTests
//
//  Tests for document session restore functionality.
//

import XCTest
@testable import Edith

final class SessionRestoreTests: XCTestCase {
    
    var restoreManager: DocumentRestoreManager!
    
    override func setUp() {
        super.setUp()
        restoreManager = DocumentRestoreManager.shared
        // Clear any existing data
        restoreManager.clearOpenDocuments()
        restoreManager.clearAllBackups()
    }
    
    override func tearDown() {
        restoreManager.clearOpenDocuments()
        restoreManager.clearAllBackups()
        super.tearDown()
    }
    
    // MARK: - Open Documents Persistence Tests
    
    func testSaveAndLoadOpenDocuments() {
        // Given: A list of open documents
        let docs = [
            DocumentRestoreManager.OpenDocumentInfo(
                path: "/Users/test/Documents/file1.txt",
                hasUnsavedChanges: false,
                restoreID: "file1_txt"
            ),
            DocumentRestoreManager.OpenDocumentInfo(
                path: "/Users/test/Documents/file2.txt",
                hasUnsavedChanges: true,
                restoreID: "file2_txt"
            )
        ]
        
        // When: Saving the documents
        restoreManager.saveOpenDocuments(docs)
        
        // Then: Loading should return the same documents
        let loaded = restoreManager.loadOpenDocuments()
        XCTAssertEqual(loaded.count, 2, "Should load 2 documents")
        XCTAssertEqual(loaded[0].path, "/Users/test/Documents/file1.txt")
        XCTAssertEqual(loaded[1].path, "/Users/test/Documents/file2.txt")
        XCTAssertFalse(loaded[0].hasUnsavedChanges)
        XCTAssertTrue(loaded[1].hasUnsavedChanges)
    }
    
    func testLoadOpenDocumentsWhenEmpty() {
        // Given: No saved documents
        restoreManager.clearOpenDocuments()
        
        // When: Loading
        let loaded = restoreManager.loadOpenDocuments()
        
        // Then: Should return empty array
        XCTAssertEqual(loaded.count, 0, "Should return empty array when no documents saved")
    }
    
    func testClearOpenDocuments() {
        // Given: Saved documents
        let docs = [
            DocumentRestoreManager.OpenDocumentInfo(
                path: "/test/path.txt",
                hasUnsavedChanges: false,
                restoreID: "test"
            )
        ]
        restoreManager.saveOpenDocuments(docs)
        XCTAssertEqual(restoreManager.loadOpenDocuments().count, 1)
        
        // When: Clearing
        restoreManager.clearOpenDocuments()
        
        // Then: Should be empty
        XCTAssertEqual(restoreManager.loadOpenDocuments().count, 0)
    }
    
    // MARK: - Unsaved Content Backup Tests
    
    func testSaveAndLoadUnsavedContent() {
        // Given: Content to backup
        let content = "This is unsaved content\nWith multiple lines"
        let restoreID = "test_backup"
        
        // When: Saving
        restoreManager.saveUnsavedContent(content, restoreID: restoreID)
        
        // Then: Should load the same content
        let loaded = restoreManager.loadUnsavedContent(restoreID: restoreID)
        XCTAssertEqual(loaded, content)
    }
    
    func testLoadUnsavedContentWhenNotExists() {
        // Given: No backup exists
        let restoreID = "nonexistent_backup"
        
        // When: Loading
        let loaded = restoreManager.loadUnsavedContent(restoreID: restoreID)
        
        // Then: Should return nil
        XCTAssertNil(loaded)
    }
    
    func testClearUnsavedContent() {
        // Given: Saved backup
        let restoreID = "clear_test"
        restoreManager.saveUnsavedContent("test content", restoreID: restoreID)
        XCTAssertNotNil(restoreManager.loadUnsavedContent(restoreID: restoreID))
        
        // When: Clearing
        restoreManager.clearUnsavedContent(restoreID: restoreID)
        
        // Then: Should be nil
        XCTAssertNil(restoreManager.loadUnsavedContent(restoreID: restoreID))
    }
    
    // MARK: - Settings Integration Tests
    
    func testReopenDocumentsSettingDefaultsToTrue() {
        let settings = SettingsManager()
        XCTAssertTrue(settings.reopenDocumentsOnLaunch, "Re-open documents should default to true")
    }
    
    func testRestoreUnsavedChangesSettingDefaultsToTrue() {
        let settings = SettingsManager()
        XCTAssertTrue(settings.restoreUnsavedChanges, "Restore unsaved changes should default to true")
    }
    
    func testRefreshDocumentsSettingDefaultsToTrue() {
        let settings = SettingsManager()
        XCTAssertTrue(settings.refreshDocumentsChangedOnDisk, "Refresh documents should default to true")
    }
    
    // MARK: - Round-trip Integration Test
    
    func testFullRoundTripPersistence() {
        // This test verifies the complete save/load cycle
        
        // Given: Multiple documents with various states
        let docs = [
            DocumentRestoreManager.OpenDocumentInfo(
                path: "/path/to/document1.txt",
                hasUnsavedChanges: false,
                restoreID: "doc1"
            ),
            DocumentRestoreManager.OpenDocumentInfo(
                path: "/path/to/document2.txt",
                hasUnsavedChanges: true,
                restoreID: "doc2"
            ),
            DocumentRestoreManager.OpenDocumentInfo(
                path: "/path/to/document3.txt",
                hasUnsavedChanges: false,
                restoreID: "doc3"
            )
        ]
        
        // Save unsaved content for doc2
        let unsavedContent = "Unsaved changes in document 2"
        restoreManager.saveUnsavedContent(unsavedContent, restoreID: "doc2")
        
        // When: Saving documents
        restoreManager.saveOpenDocuments(docs)
        
        // Then: Everything should be retrievable
        let loadedDocs = restoreManager.loadOpenDocuments()
        XCTAssertEqual(loadedDocs.count, 3)
        
        // Find doc2 and verify unsaved content
        let doc2 = loadedDocs.first { $0.restoreID == "doc2" }
        XCTAssertNotNil(doc2)
        XCTAssertTrue(doc2!.hasUnsavedChanges)
        
        let loadedContent = restoreManager.loadUnsavedContent(restoreID: "doc2")
        XCTAssertEqual(loadedContent, unsavedContent)
    }
    
    // MARK: - UserDefaults Integration Tests
    
    func testReopenDocumentsUserDefaultsReadingWhenKeyNotSet() {
        // Given: The key is not set in UserDefaults (simulating first launch)
        UserDefaults.standard.removeObject(forKey: "reopenDocumentsOnLaunch")
        
        // When: Reading the value (as the AppDelegate does)
        let valueExists = UserDefaults.standard.object(forKey: "reopenDocumentsOnLaunch") != nil
        let defaultValue = valueExists ? UserDefaults.standard.bool(forKey: "reopenDocumentsOnLaunch") : true
        
        // Then: Should default to true
        XCTAssertTrue(defaultValue, "Should default to true when key not set")
    }
    
    func testReopenDocumentsUserDefaultsReadingWhenSetToTrue() {
        // Given: The key is explicitly set to true
        UserDefaults.standard.set(true, forKey: "reopenDocumentsOnLaunch")
        
        // When: Reading the value
        let value = UserDefaults.standard.bool(forKey: "reopenDocumentsOnLaunch")
        
        // Then: Should be true
        XCTAssertTrue(value)
    }
    
    func testReopenDocumentsUserDefaultsReadingWhenSetToFalse() {
        // Given: The key is explicitly set to false
        UserDefaults.standard.set(false, forKey: "reopenDocumentsOnLaunch")
        
        // When: Reading the value
        let value = UserDefaults.standard.bool(forKey: "reopenDocumentsOnLaunch")
        
        // Then: Should be false
        XCTAssertFalse(value)
        
        // Cleanup: Reset to default
        UserDefaults.standard.removeObject(forKey: "reopenDocumentsOnLaunch")
    }
}
