//
//  FindReplaceWindow.swift
//  Edith
//

import SwiftUI

/// Find & Replace window view
struct FindReplaceView: View {
    @ObservedObject var state: FindReplaceState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Find field
            HStack {
                Text("Find:")
                    .frame(width: 60, alignment: .trailing)
                TextField("Search text", text: $state.findText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        state.findNext()
                    }
            }
            
            // Replace field
            HStack {
                Text("Replace:")
                    .frame(width: 60, alignment: .trailing)
                TextField("Replacement text", text: $state.replaceText)
                    .textFieldStyle(.roundedBorder)
            }
            
            Divider()
            
            // Options
            HStack(spacing: 16) {
                Toggle("Case sensitive", isOn: $state.caseSensitive)
                    .onChange(of: state.caseSensitive) { _ in state.performSearch() }
                
                Toggle("PCRE syntax", isOn: $state.usePCRE)
                    .onChange(of: state.usePCRE) { _ in state.performSearch() }
            }
            
            HStack(spacing: 16) {
                Toggle("Selected text only", isOn: $state.selectedTextOnly)
                    .disabled(state.initialSelectionRange == nil)
                    .onChange(of: state.selectedTextOnly) { _ in state.performSearch() }
                
                Toggle("Wrap around", isOn: $state.wrapAround)
            }
            
            Divider()
            
            // Match count
            if !state.findText.isEmpty {
                HStack {
                    if state.hasMatches {
                        Text("\(state.currentMatchIndex + 1) of \(state.totalMatches) matches")
                            .foregroundColor(.secondary)
                    } else {
                        Text("No matches")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            
            // Action buttons
            HStack(spacing: 8) {
                Button("Find Previous") {
                    state.findPrevious()
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                
                Button("Find Next") {
                    state.findNext()
                }
                .keyboardShortcut("g", modifiers: .command)
                
                Button("Find All") {
                    state.findAll()
                }
                
                Button("Extract All") {
                    state.extractAll()
                }
            }
            
            HStack(spacing: 8) {
                Button("Replace Next") {
                    state.replaceNext()
                }
                
                Button("Replace All") {
                    state.replaceAll()
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
        }
        .padding()
        .frame(minWidth: 450, minHeight: 220)
        .onAppear {
            state.captureSelection()
            if !state.findText.isEmpty {
                state.performSearch()
            }
        }
    }
}

// MARK: - FocusedValue for FindReplaceState
struct FindReplaceStateKey: FocusedValueKey {
    typealias Value = FindReplaceState
}

extension FocusedValues {
    var findReplaceState: FindReplaceState? {
        get { self[FindReplaceStateKey.self] }
        set { self[FindReplaceStateKey.self] = newValue }
    }
}
