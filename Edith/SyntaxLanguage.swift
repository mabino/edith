//
//  SyntaxLanguage.swift
//  Edith
//

import Foundation

/// Supported syntax languages for highlighting
enum SyntaxLanguage: String, CaseIterable, Identifiable, Codable {
    case auto = "auto"
    case plain = "plain"
    case html = "html"
    case css = "css"
    case python = "python"
    case json = "json"
    case markdown = "markdown"
    case javascript = "javascript"
    case swift = "swift"
    case xml = "xml"
    case yaml = "yaml"
    case sql = "sql"
    case shell = "shell"
    
    var id: String { rawValue }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .auto: return "Auto-Detect"
        case .plain: return "Plain Text"
        case .html: return "HTML"
        case .css: return "CSS"
        case .python: return "Python"
        case .json: return "JSON"
        case .markdown: return "Markdown"
        case .javascript: return "JavaScript"
        case .swift: return "Swift"
        case .xml: return "XML"
        case .yaml: return "YAML"
        case .sql: return "SQL"
        case .shell: return "Shell"
        }
    }
    
    /// Language identifier for HighlightSwift
    /// Returns nil for auto-detect mode
    var highlightLanguage: String? {
        switch self {
        case .auto: return nil
        case .plain: return nil
        case .html: return "html"
        case .css: return "css"
        case .python: return "python"
        case .json: return "json"
        case .markdown: return "markdown"
        case .javascript: return "javascript"
        case .swift: return "swift"
        case .xml: return "xml"
        case .yaml: return "yaml"
        case .sql: return "sql"
        case .shell: return "bash"
        }
    }
    
    /// Detect language from file extension
    static func detect(from url: URL?) -> SyntaxLanguage {
        guard let ext = url?.pathExtension.lowercased() else { return .auto }
        
        switch ext {
        case "html", "htm":
            return .html
        case "css":
            return .css
        case "py", "pyw":
            return .python
        case "json":
            return .json
        case "md", "markdown":
            return .markdown
        case "js", "mjs", "cjs":
            return .javascript
        case "swift":
            return .swift
        case "xml", "xsd", "xsl", "plist":
            return .xml
        case "yml", "yaml":
            return .yaml
        case "sql":
            return .sql
        case "sh", "bash", "zsh", "fish":
            return .shell
        case "txt", "text":
            return .plain
        default:
            return .auto
        }
    }
    
    /// Core languages that should always appear first in UI
    static var coreLanguages: [SyntaxLanguage] {
        [.auto, .plain, .html, .css, .python, .json, .markdown]
    }
    
    /// All languages except auto and plain (for display in "More" submenu)
    static var additionalLanguages: [SyntaxLanguage] {
        allCases.filter { $0 != .auto && $0 != .plain && !coreLanguages.contains($0) }
    }
}
