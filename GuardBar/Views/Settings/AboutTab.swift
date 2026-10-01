//
//  AboutTab.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/11/25.
//

import SwiftUI

struct AboutTab: View {
    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "Version \(version) (\(build))"
    }

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
                            Text(versionText)
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
