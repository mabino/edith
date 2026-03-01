//
//  VimMode.swift
//  Edith
//
//  Vim-like modal editing support
//

import Foundation
import AppKit
import SwiftUI
import Combine

// MARK: - Vim Mode Enum
enum VimMode: Equatable {
    case insert      // Normal text editing (default)
    case normal      // Vim normal mode - navigation and commands
    case command     // Command-line mode (after pressing :)
}

// MARK: - Vim Mode State (per-document)
class VimModeState: ObservableObject {
    @Published var mode: VimMode = .insert
    @Published var commandText: String = ""
    @Published var statusMessage: String = ""
    
    // Double-tap detection
    private var lastEscTime: Date?
    private let doubleTapThreshold: TimeInterval = 0.3
    
    // Number prefix for commands (e.g., 5j, 10G)
    private var numberPrefix: String = ""
    
    // Operator pending mode (e.g., after pressing 'd')
    private var pendingOperator: String = ""
    private var operatorCount: Int = 1
    
    // Reference to text view for executing commands
    weak var textView: NSTextView?
    
    // MARK: - Double-tap Esc Detection
    
    /// Returns true if this Esc press completes a double-tap
    func handleEscPress() -> Bool {
        let now = Date()
        
        if let lastTime = lastEscTime,
           now.timeIntervalSince(lastTime) < doubleTapThreshold {
            // Double-tap detected
            lastEscTime = nil
            toggleNormalMode()
            return true
        }
        
        lastEscTime = now
        
        // Schedule clearing of single tap after threshold
        DispatchQueue.main.asyncAfter(deadline: .now() + doubleTapThreshold) { [weak self] in
            // If still waiting for second tap, handle single Esc
            if let lastTime = self?.lastEscTime, lastTime == now {
                self?.handleSingleEsc()
                self?.lastEscTime = nil
            }
        }
        
        return false
    }
    
    private func handleSingleEsc() {
        // Single Esc in command mode returns to normal mode
        if mode == .command {
            mode = .normal
            commandText = ""
        }
    }
    
    private func toggleNormalMode() {
        switch mode {
        case .insert:
            mode = .normal
            statusMessage = "-- NORMAL --"
        case .normal, .command:
            mode = .insert
            commandText = ""
            statusMessage = ""
        }
    }
    
    // MARK: - Normal Mode Key Handling
    
    /// Handle a key press in normal mode. Returns true if handled.
    func handleNormalModeKey(_ key: String, modifiers: NSEvent.ModifierFlags) -> Bool {
        guard mode == .normal, let textView = textView else { return false }
        
        // Handle digit keys for number prefix (except 0 at start which is line start)
        // Also handle digits after pending operator (e.g., d3w)
        if key >= "1" && key <= "9" || (key == "0" && !numberPrefix.isEmpty) {
            numberPrefix += key
            statusMessage = pendingOperator + numberPrefix
            return true
        }
        
        // Get count from number prefix (default 1)
        let count = Int(numberPrefix) ?? 1
        
        // If we have a pending operator, handle motion
        if !pendingOperator.isEmpty {
            return handleOperatorMotion(operator: pendingOperator, motion: key, count: count * operatorCount, textView: textView)
        }
        
        switch key {
        // Navigation - basic movement
        case "h":
            for _ in 0..<count { moveLeft(textView) }
            clearState()
        case "j":
            for _ in 0..<count { moveDown(textView) }
            clearState()
        case "k":
            for _ in 0..<count { moveUp(textView) }
            clearState()
        case "l":
            for _ in 0..<count { moveRight(textView) }
            clearState()
            
        // Word navigation
        case "w":
            for _ in 0..<count { moveWordForward(textView) }
            clearState()
        case "b":
            for _ in 0..<count { moveWordBackward(textView) }
            clearState()
        case "e":
            for _ in 0..<count { moveToEndOfWord(textView) }
            clearState()
            
        // Line navigation
        case "0":
            moveToStartOfLine(textView)
            clearState()
        case "$":
            moveToEndOfLine(textView)
            clearState()
        case "^":
            moveToFirstNonBlank(textView)
            clearState()
            
        // Document navigation
        case "G":
            if !numberPrefix.isEmpty {
                // nG goes to line n
                goToLine(count)
            } else {
                // G alone goes to end
                moveToEndOfDocument(textView)
            }
            clearState()
        case "g":
            // Track for gg command
            if statusMessage.hasSuffix("g") {
                moveToStartOfDocument(textView)
                clearState()
            } else {
                statusMessage = numberPrefix + "g"
            }
            return true
            
        // Insert mode entry
        case "i":
            mode = .insert
            statusMessage = "-- INSERT --"
            clearState()
        case "a":
            moveRight(textView)
            mode = .insert
            statusMessage = "-- INSERT --"
            clearState()
        case "I":
            moveToFirstNonBlank(textView)
            mode = .insert
            statusMessage = "-- INSERT --"
            clearState()
        case "A":
            moveToEndOfLine(textView)
            mode = .insert
            statusMessage = "-- INSERT --"
            clearState()
        case "o":
            insertLineBelow(textView)
            mode = .insert
            statusMessage = "-- INSERT --"
            clearState()
        case "O":
            insertLineAbove(textView)
            mode = .insert
            statusMessage = "-- INSERT --"
            clearState()
            
        // Command mode
        case ":":
            mode = .command
            commandText = ""
            statusMessage = ":"
            clearState()
            
        // Delete
        case "x":
            for _ in 0..<count { deleteCharacter(textView) }
            clearState()
        case "d":
            if statusMessage.hasSuffix("d") {
                // dd - delete line(s)
                let lineCount = operatorCount * count
                for _ in 0..<lineCount { deleteLine(textView) }
                clearState()
            } else {
                // Enter operator pending mode
                pendingOperator = "d"
                operatorCount = count
                numberPrefix = ""
                statusMessage = (count > 1 ? "\(count)" : "") + "d"
            }
            return true
            
        default:
            // Check for composed commands
            if statusMessage.hasSuffix("g") && key == "g" {
                moveToStartOfDocument(textView)
                clearState()
            } else {
                clearState()
                return false
            }
        }
        
        return true
    }
    
    // Clear all pending state
    private func clearState() {
        numberPrefix = ""
        pendingOperator = ""
        operatorCount = 1
        statusMessage = ""
    }
    
    // Handle motion after an operator (e.g., d3w)
    private func handleOperatorMotion(operator op: String, motion: String, count: Int, textView: NSTextView) -> Bool {
        let startLocation = textView.selectedRange().location
        
        // Handle the motion to determine the range
        switch motion {
        case "w":
            // Move forward count words to get end position
            for _ in 0..<count { moveWordForward(textView) }
        case "e":
            for _ in 0..<count { moveToEndOfWord(textView) }
            // Include the character at end of word
            let range = textView.selectedRange()
            if range.location < textView.string.count {
                textView.setSelectedRange(NSRange(location: range.location + 1, length: 0))
            }
        case "b":
            for _ in 0..<count { moveWordBackward(textView) }
        case "h":
            for _ in 0..<count { moveLeft(textView) }
        case "l":
            for _ in 0..<count { moveRight(textView) }
        case "$":
            moveToEndOfLine(textView)
        case "0":
            moveToStartOfLine(textView)
        case "^":
            moveToFirstNonBlank(textView)
        case "d":
            // dd - delete line(s)
            for _ in 0..<count { deleteLine(textView) }
            clearState()
            return true
        default:
            clearState()
            return false
        }
        
        let endLocation = textView.selectedRange().location
        
        // Calculate the range to operate on
        let rangeStart = min(startLocation, endLocation)
        let rangeEnd = max(startLocation, endLocation)
        let operationRange = NSRange(location: rangeStart, length: rangeEnd - rangeStart)
        
        // Execute the operator
        switch op {
        case "d":
            if operationRange.length > 0 {
                if textView.shouldChangeText(in: operationRange, replacementString: "") {
                    textView.replaceCharacters(in: operationRange, with: "")
                    textView.didChangeText()
                }
            }
        default:
            break
        }
        
        // Position cursor at start of operated region
        textView.setSelectedRange(NSRange(location: rangeStart, length: 0))
        
        clearState()
        return true
    }
    
    // MARK: - Command Mode
    
    func handleCommandKey(_ key: String) -> Bool {
        guard mode == .command else { return false }
        
        if key == "\r" || key == "\n" {
            // Execute command
            executeCommand(commandText)
            return true
        }
        
        return false
    }
    
    func appendToCommand(_ char: Character) {
        commandText.append(char)
        statusMessage = ":" + commandText
    }
    
    func deleteFromCommand() {
        if !commandText.isEmpty {
            commandText.removeLast()
            statusMessage = ":" + commandText
        } else {
            // Empty command, return to normal mode
            mode = .normal
            statusMessage = "-- NORMAL --"
        }
    }
    
    // MARK: - Command Execution
    
    private func executeCommand(_ command: String) {
        let trimmed = command.trimmingCharacters(in: .whitespaces)
        
        switch trimmed {
        case "w":
            saveDocument()
            mode = .normal
            statusMessage = "Saved"
        case "q":
            closeDocument(force: false)
        case "q!":
            closeDocument(force: true)
        case "wq", "x":
            saveDocument()
            closeDocument(force: false)
        case "wq!":
            saveDocument()
            closeDocument(force: true)
        default:
            // Check for substitution command
            if trimmed.hasPrefix("s/") || trimmed.hasPrefix("%s/") {
                executeSubstitution(trimmed)
            } else if let lineNum = Int(trimmed) {
                goToLine(lineNum)
            } else {
                statusMessage = "Unknown command: \(trimmed)"
            }
        }
        
        commandText = ""
        if mode == .command {
            mode = .normal
        }
    }
    
    // MARK: - Navigation Commands
    
    private func moveLeft(_ textView: NSTextView) {
        let range = textView.selectedRange()
        if range.location > 0 {
            textView.setSelectedRange(NSRange(location: range.location - 1, length: 0))
        }
    }
    
    private func moveRight(_ textView: NSTextView) {
        let range = textView.selectedRange()
        if range.location < textView.string.count {
            textView.setSelectedRange(NSRange(location: range.location + 1, length: 0))
        }
    }
    
    private func moveUp(_ textView: NSTextView) {
        textView.moveUp(nil)
    }
    
    private func moveDown(_ textView: NSTextView) {
        textView.moveDown(nil)
    }
    
    private func moveWordForward(_ textView: NSTextView) {
        textView.moveWordForward(nil)
    }
    
    private func moveWordBackward(_ textView: NSTextView) {
        textView.moveWordBackward(nil)
    }
    
    private func moveToEndOfWord(_ textView: NSTextView) {
        // Vim's `e` moves to end of current/next word
        let content = textView.string as NSString
        var location = textView.selectedRange().location
        
        guard location < content.length else { return }
        
        // Skip current character
        location += 1
        
        // Skip whitespace
        while location < content.length {
            let char = Character(UnicodeScalar(content.character(at: location))!)
            if !char.isWhitespace {
                break
            }
            location += 1
        }
        
        // Move to end of word (stop before whitespace or punctuation)
        while location < content.length {
            let char = Character(UnicodeScalar(content.character(at: location))!)
            if char.isWhitespace || char.isPunctuation {
                break
            }
            location += 1
        }
        
        // Position at last character of word
        if location > 0 {
            location -= 1
        }
        
        textView.setSelectedRange(NSRange(location: location, length: 0))
        textView.scrollRangeToVisible(NSRange(location: location, length: 0))
    }
    
    private func moveToStartOfLine(_ textView: NSTextView) {
        textView.moveToBeginningOfLine(nil)
    }
    
    private func moveToEndOfLine(_ textView: NSTextView) {
        textView.moveToEndOfLine(nil)
    }
    
    private func moveToFirstNonBlank(_ textView: NSTextView) {
        textView.moveToBeginningOfLine(nil)
        let content = textView.string as NSString
        var location = textView.selectedRange().location
        while location < content.length {
            let char = content.character(at: location)
            if char != 0x20 && char != 0x09 { // space, tab
                break
            }
            location += 1
        }
        textView.setSelectedRange(NSRange(location: location, length: 0))
    }
    
    private func moveToStartOfDocument(_ textView: NSTextView) {
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
    }
    
    private func moveToEndOfDocument(_ textView: NSTextView) {
        let end = textView.string.count
        textView.setSelectedRange(NSRange(location: end, length: 0))
        textView.scrollRangeToVisible(NSRange(location: end, length: 0))
    }
    
    // MARK: - Insert Commands
    
    private func insertLineBelow(_ textView: NSTextView) {
        textView.moveToEndOfLine(nil)
        textView.insertNewline(nil)
    }
    
    private func insertLineAbove(_ textView: NSTextView) {
        textView.moveToBeginningOfLine(nil)
        textView.insertNewline(nil)
        textView.moveUp(nil)
    }
    
    // MARK: - Edit Commands
    
    private func deleteCharacter(_ textView: NSTextView) {
        let range = textView.selectedRange()
        let content = textView.string as NSString
        if range.location < content.length {
            let deleteRange = NSRange(location: range.location, length: 1)
            if textView.shouldChangeText(in: deleteRange, replacementString: "") {
                textView.replaceCharacters(in: deleteRange, with: "")
                textView.didChangeText()
            }
        }
    }
    
    private func deleteLine(_ textView: NSTextView) {
        let content = textView.string as NSString
        guard content.length > 0 else { return }
        
        let currentRange = textView.selectedRange()
        let lineRange = content.lineRange(for: currentRange)
        
        if textView.shouldChangeText(in: lineRange, replacementString: "") {
            textView.replaceCharacters(in: lineRange, with: "")
            textView.didChangeText()
            
            // Position cursor at start of next line (or end of document)
            let newLocation = min(lineRange.location, textView.string.count)
            textView.setSelectedRange(NSRange(location: newLocation, length: 0))
        }
    }
    
    // MARK: - Document Commands
    
    private func saveDocument() {
        guard let window = textView?.window,
              let windowController = window.windowController,
              let document = windowController.document as? NSDocument else {
            statusMessage = "No document"
            return
        }
        
        if document.fileURL != nil {
            document.save(nil)
            statusMessage = "Saved"
        } else {
            // Trigger Save As for new documents
            NSApp.sendAction(#selector(NSDocument.save(_:)), to: nil, from: nil)
            statusMessage = "Saving..."
        }
    }
    
    private func closeDocument(force: Bool) {
        guard let window = textView?.window else { return }
        
        if force {
            // Close without saving
            if let windowController = window.windowController,
               let document = windowController.document as? NSDocument {
                document.updateChangeCount(.changeCleared)
            }
        }
        window.close()
    }
    
    private func goToLine(_ lineNumber: Int) {
        guard let textView = textView else { return }
        let content = textView.string as NSString
        
        var currentLine = 1
        var idx = 0
        
        while idx < content.length && currentLine < lineNumber {
            let range = content.lineRange(for: NSRange(location: idx, length: 0))
            currentLine += 1
            idx = NSMaxRange(range)
        }
        
        textView.setSelectedRange(NSRange(location: idx, length: 0))
        textView.scrollRangeToVisible(NSRange(location: idx, length: 0))
        statusMessage = "Line \(lineNumber)"
    }
    
    private func executeSubstitution(_ command: String) {
        guard let textView = textView else { return }
        
        // Parse: s/pattern/replacement/flags or %s/pattern/replacement/flags
        let isGlobal = command.hasPrefix("%")
        let cmdPart = isGlobal ? String(command.dropFirst()) : command
        
        // Remove leading s
        guard cmdPart.hasPrefix("s/") else { return }
        let parts = String(cmdPart.dropFirst(2))
        
        // Split by / but handle escaped \/
        var components: [String] = []
        var current = ""
        var escaped = false
        
        for char in parts {
            if escaped {
                current.append(char)
                escaped = false
            } else if char == "\\" {
                escaped = true
                current.append(char)
            } else if char == "/" {
                components.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        components.append(current)
        
        guard components.count >= 2 else {
            statusMessage = "Invalid substitution"
            return
        }
        
        let pattern = components[0]
        let replacement = components[1]
        let flags = components.count > 2 ? components[2] : ""
        let replaceAll = flags.contains("g")
        
        // Perform substitution
        let content = textView.string
        var searchRange: Range<String.Index>
        
        if isGlobal {
            searchRange = content.startIndex..<content.endIndex
        } else {
            // Current line only
            let nsRange = (content as NSString).lineRange(for: textView.selectedRange())
            guard let range = Range(nsRange, in: content) else { return }
            searchRange = range
        }
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsSearchRange = NSRange(searchRange, in: content)
            
            if replaceAll {
                let newContent = regex.stringByReplacingMatches(
                    in: content,
                    options: [],
                    range: nsSearchRange,
                    withTemplate: replacement
                )
                textView.string = newContent
                statusMessage = "Substitution complete"
            } else {
                // Replace first match only
                if let match = regex.firstMatch(in: content, options: [], range: nsSearchRange) {
                    textView.setSelectedRange(match.range)
                    textView.insertText(replacement, replacementRange: match.range)
                    statusMessage = "1 substitution"
                } else {
                    statusMessage = "Pattern not found"
                }
            }
        } catch {
            statusMessage = "Invalid regex"
        }
    }
}

// MARK: - Vim Command Bar View
struct VimCommandBar: View {
    @ObservedObject var vimState: VimModeState
    
    var body: some View {
        HStack(spacing: 0) {
            Text(":")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
            
            Text(vimState.commandText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
            
            // Cursor indicator
            Rectangle()
                .fill(Color.primary)
                .frame(width: 8, height: 16)
                .opacity(0.7)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .stroke(Color.green.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Vim Mode Glow Overlay
struct VimModeGlowOverlay: View {
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.green, lineWidth: 3)
                    .shadow(color: Color.green.opacity(0.8), radius: 8, x: 0, y: 0)
            )
            .allowsHitTesting(false)
    }
}
