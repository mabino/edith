//
//  SyntaxHighlighter.swift
//  Edith
//

import Foundation
import AppKit
import HighlightSwift

/// Wrapper around HighlightSwift for syntax highlighting
@MainActor
class SyntaxHighlighter: ObservableObject {
    private let highlight = Highlight()
    
    @Published var detectedLanguage: String?
    @Published var isHighlighting: Bool = false
    
    private var debounceTask: Task<Void, Never>?
    private let debounceDelay: TimeInterval = 0.3
    
    /// Highlight text with optional language specification
    /// - Parameters:
    ///   - text: The text to highlight
    ///   - language: The language to use (nil for auto-detect)
    ///   - textStorage: The NSTextStorage to apply highlighting to
    ///   - baseFont: The base font to use
    func highlightText(
        _ text: String,
        language: SyntaxLanguage,
        textStorage: NSTextStorage,
        baseFont: NSFont
    ) {
        // Cancel any pending debounce
        debounceTask?.cancel()
        
        // Plain text = no highlighting
        if language == .plain {
            applyPlainText(text, textStorage: textStorage, baseFont: baseFont)
            detectedLanguage = nil
            return
        }
        
        // Start debounce
        debounceTask = Task { [weak self] in
            do {
                // Wait for debounce
                try await Task.sleep(nanoseconds: UInt64(self?.debounceDelay ?? 0.3) * 1_000_000_000)
                
                guard !Task.isCancelled else { return }
                
                await self?.performHighlighting(text: text, language: language, textStorage: textStorage, baseFont: baseFont)
            } catch {
                // Task was cancelled, ignore
            }
        }
    }
    
    /// Immediate highlighting without debounce (for initial load)
    func highlightImmediately(
        _ text: String,
        language: SyntaxLanguage,
        textStorage: NSTextStorage,
        baseFont: NSFont
    ) async {
        await performHighlighting(text: text, language: language, textStorage: textStorage, baseFont: baseFont)
    }
    
    private func performHighlighting(
        text: String,
        language: SyntaxLanguage,
        textStorage: NSTextStorage,
        baseFont: NSFont
    ) async {
        guard !text.isEmpty else {
            applyPlainText(text, textStorage: textStorage, baseFont: baseFont)
            return
        }
        
        isHighlighting = true
        defer { isHighlighting = false }
        
        do {
            let result: HighlightResult
            let colors = SyntaxHighlighter.colors(for: NSApp.effectiveAppearance)
            
            if let langId = language.highlightLanguage {
                // Use specified language
                result = try await highlight.request(text, mode: .languageAlias(langId), colors: colors)
            } else {
                // Auto-detect
                result = try await highlight.request(text, mode: .automatic, colors: colors)
            }
            
            // Update detected language
            detectedLanguage = result.languageName
            
            // Apply the attributed string while preserving font
            applyHighlightedText(result.attributedText, textStorage: textStorage, baseFont: baseFont)
            
        } catch {
            // On error, fall back to plain text
            applyPlainText(text, textStorage: textStorage, baseFont: baseFont)
        }
    }
    
    private func applyHighlightedText(
        _ attributedText: AttributedString,
        textStorage: NSTextStorage,
        baseFont: NSFont
    ) {
        // Convert to NSAttributedString
        let nsAttrString = NSMutableAttributedString(attributedText)
        
        // Preserve the base font size throughout
        let fullRange = NSRange(location: 0, length: nsAttrString.length)
        nsAttrString.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
            if let existingFont = value as? NSFont {
                // Keep the font family/style from highlighting but use base size
                let newFont = NSFont(descriptor: existingFont.fontDescriptor, size: baseFont.pointSize)
                    ?? baseFont
                nsAttrString.addAttribute(.font, value: newFont, range: range)
            } else {
                nsAttrString.addAttribute(.font, value: baseFont, range: range)
            }
        }
        
        // Apply to text storage
        let selectedRanges = textStorage.layoutManagers.first?.textViewForBeginningOfSelection?.selectedRanges ?? []
        
        textStorage.beginEditing()
        textStorage.setAttributedString(nsAttrString)
        textStorage.endEditing()
        
        // Restore selection if possible
        if let textView = textStorage.layoutManagers.first?.textViewForBeginningOfSelection {
            textView.selectedRanges = selectedRanges
        }
    }
    
    private func applyPlainText(
        _ text: String,
        textStorage: NSTextStorage,
        baseFont: NSFont
    ) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: NSColor.textColor
        ]
        
        let selectedRanges = textStorage.layoutManagers.first?.textViewForBeginningOfSelection?.selectedRanges ?? []
        
        textStorage.beginEditing()
        textStorage.setAttributedString(NSAttributedString(string: text, attributes: attrs))
        textStorage.endEditing()
        
        // Restore selection if possible
        if let textView = textStorage.layoutManagers.first?.textViewForBeginningOfSelection {
            textView.selectedRanges = selectedRanges
        }
    }
}

// MARK: - Theme Colors for Light/Dark Mode
extension SyntaxHighlighter {
    /// Get appropriate HighlightSwift colors for current appearance
    static func colors(for appearance: NSAppearance?) -> HighlightColors {
        let isDark = appearance?.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return isDark ? .dark(.github) : .light(.github)
    }
}
