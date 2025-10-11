//
//  StatsView.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/11/25.
//

import SwiftUI

/// Displays AdGuard Home DNS statistics
struct StatsView: View {
    let stats: AGHStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatRow(label: "Queries Today", value: "\(stats.numDnsQueries.formatted())")
            StatRow(label: "Blocked Today", value: "\(stats.numBlockedFiltering.formatted())")
            StatRow(label: "Block Rate", value: String(format: "%.1f%%", stats.blockPercentage))
        }
        .padding()
    }
}

// Reusable stats row component
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    StatsView(stats: AGHStats(
        numDnsQueries: 12543,
        numBlockedFiltering: 3421,
        numReplacedSafebrowsing: 12,
        avgProcessingTime: 0.05
    ))
    .frame(width: 300)
}
