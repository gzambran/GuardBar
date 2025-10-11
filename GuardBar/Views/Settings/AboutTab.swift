//
//  AboutTab.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/11/25.
//

import SwiftUI

struct AboutTab: View {
    var body: some View {
        Form {
            Section("About GuardBar") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("GuardBar")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Version 1.0.0")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    Text("A macOS menu bar app for managing AdGuard Home")
                        .foregroundColor(.secondary)
                    
                    Link("View on GitHub", destination: URL(string: "https://github.com/gzambran/GuardBar")!)
                    
                    Divider()
                    
                    Text("Created by Giancarlos Zambrano")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("MIT License")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    AboutTab()
}
