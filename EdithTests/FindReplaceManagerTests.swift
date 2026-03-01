//
//  FindReplaceManagerTests.swift
//  EdithTests
//

import XCTest
@testable import Edith

@MainActor
final class FindReplaceManagerTests: XCTestCase {
    
    var manager: FindReplaceManager!
    
    override func setUp() async throws {
        manager = FindReplaceManager.shared
        // Clear any existing state
        for doc in manager.documents {
            manager.unregisterState(doc.state)
        }
    }
    
    override func tearDown() async throws {
        // Clean up
        for doc in manager.documents {
            manager.unregisterState(doc.state)
        }
    }
    
    // MARK: - Registration Tests
    
    func testRegisterSingleDocument() {
        let state = FindReplaceState()
        
        manager.registerActiveState(state, documentName: "Test.txt")
        
        XCTAssertEqual(manager.documents.count, 1)
        XCTAssertEqual(manager.documents.first?.name, "Test.txt")
        XCTAssertTrue(manager.activeState === state)
    }
    
    func testRegisterMultipleDocuments() {
        let state1 = FindReplaceState()
        let state2 = FindReplaceState()
        let state3 = FindReplaceState()
        
        manager.registerActiveState(state1, documentName: "Untitled")
        manager.registerActiveState(state2, documentName: "Untitled 2")
        manager.registerActiveState(state3, documentName: "test.py")
        
        XCTAssertEqual(manager.documents.count, 3)
        
        let names = manager.documents.map { $0.name }.sorted()
        XCTAssertEqual(names, ["Untitled", "Untitled 2", "test.py"])
    }
    
    func testRegisterSetsActiveState() {
        let state1 = FindReplaceState()
        let state2 = FindReplaceState()
        
        manager.registerActiveState(state1, documentName: "Doc1")
        XCTAssertTrue(manager.activeState === state1)
        
        manager.registerActiveState(state2, documentName: "Doc2")
        XCTAssertTrue(manager.activeState === state2)
    }
    
    func testUnregisterDocument() {
        let state1 = FindReplaceState()
        let state2 = FindReplaceState()
        
        manager.registerActiveState(state1, documentName: "Doc1")
        manager.registerActiveState(state2, documentName: "Doc2")
        
        XCTAssertEqual(manager.documents.count, 2)
        
        manager.unregisterState(state1)
        
        XCTAssertEqual(manager.documents.count, 1)
        XCTAssertEqual(manager.documents.first?.name, "Doc2")
    }
    
    func testUnregisterActiveStateSelectsFirst() {
        let state1 = FindReplaceState()
        let state2 = FindReplaceState()
        
        manager.registerActiveState(state1, documentName: "Doc1")
        manager.registerActiveState(state2, documentName: "Doc2")
        
        // state2 is now active
        XCTAssertTrue(manager.activeState === state2)
        
        // Unregister active state
        manager.unregisterState(state2)
        
        // Should select first available
        XCTAssertTrue(manager.activeState === state1)
    }
    
    func testUnregisterLastDocumentClearsActiveState() {
        let state = FindReplaceState()
        
        manager.registerActiveState(state, documentName: "Only Doc")
        XCTAssertNotNil(manager.activeState)
        
        manager.unregisterState(state)
        
        XCTAssertNil(manager.activeState)
        XCTAssertTrue(manager.documents.isEmpty)
    }
    
    // MARK: - Document Name Update Tests
    
    func testUpdateDocumentName() {
        let state = FindReplaceState()
        
        manager.registerActiveState(state, documentName: "Untitled")
        XCTAssertEqual(manager.documents.first?.name, "Untitled")
        
        manager.updateDocumentName(state, name: "MyFile.txt")
        XCTAssertEqual(manager.documents.first?.name, "MyFile.txt")
    }
    
    func testUpdateDocumentNamePreservesOtherDocuments() {
        let state1 = FindReplaceState()
        let state2 = FindReplaceState()
        
        manager.registerActiveState(state1, documentName: "Doc1")
        manager.registerActiveState(state2, documentName: "Doc2")
        
        manager.updateDocumentName(state1, name: "Renamed")
        
        let names = Set(manager.documents.map { $0.name })
        XCTAssertEqual(names, ["Renamed", "Doc2"])
    }
    
    // MARK: - Selection Tests
    
    func testSelectDocument() {
        let state1 = FindReplaceState()
        let state2 = FindReplaceState()
        
        manager.registerActiveState(state1, documentName: "Doc1")
        manager.registerActiveState(state2, documentName: "Doc2")
        
        XCTAssertTrue(manager.activeState === state2)
        
        manager.selectDocument(state1)
        
        XCTAssertTrue(manager.activeState === state1)
    }
    
    func testEnsureActiveStateWhenNil() {
        let state = FindReplaceState()
        
        manager.registerActiveState(state, documentName: "Test")
        manager.activeState = nil
        
        manager.ensureActiveState()
        
        XCTAssertTrue(manager.activeState === state)
    }
    
    func testEnsureActiveStateWhenAlreadySet() {
        let state1 = FindReplaceState()
        let state2 = FindReplaceState()
        
        manager.registerActiveState(state1, documentName: "Doc1")
        manager.registerActiveState(state2, documentName: "Doc2")
        
        manager.selectDocument(state1)
        manager.ensureActiveState()
        
        // Should keep existing selection
        XCTAssertTrue(manager.activeState === state1)
    }
    
    // MARK: - Unique Documents Tests
    
    func testEachDocumentHasUniqueIdentity() {
        let state1 = FindReplaceState()
        let state2 = FindReplaceState()
        let state3 = FindReplaceState()
        
        manager.registerActiveState(state1, documentName: "Untitled")
        manager.registerActiveState(state2, documentName: "Untitled 2")
        manager.registerActiveState(state3, documentName: "test.py")
        
        // Each document should have unique ObjectIdentifier
        let ids = Set(manager.documents.map { $0.id })
        XCTAssertEqual(ids.count, 3)
    }
    
    func testDocumentsSortedByName() {
        let state1 = FindReplaceState()
        let state2 = FindReplaceState()
        let state3 = FindReplaceState()
        
        manager.registerActiveState(state3, documentName: "Zebra.txt")
        manager.registerActiveState(state1, documentName: "Apple.txt")
        manager.registerActiveState(state2, documentName: "Banana.txt")
        
        let names = manager.documents.map { $0.name }
        XCTAssertEqual(names, ["Apple.txt", "Banana.txt", "Zebra.txt"])
    }
}
