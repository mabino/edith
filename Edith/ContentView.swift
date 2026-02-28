//
//  ContentView.swift
//  Edith
//

import SwiftUI

struct ContentView: View {
    @Binding var document: TextDocument
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        EditorView(text: $document.text)
            .environmentObject(settingsManager)
    }
}
