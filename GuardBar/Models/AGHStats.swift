//
//  AGHStats.swift
//  GuardBar
//
//  Created by Giancarlos Zambrano on 10/10/25.
//

import Foundation

struct AGHStats: Codable {
    let numDnsQueries: Int
    let numBlockedFiltering: Int
    let numReplacedSafebrowsing: Int
    let avgProcessingTime: Double
    
    enum CodingKeys: String, CodingKey {
        case numDnsQueries = "num_dns_queries"
        case numBlockedFiltering = "num_blocked_filtering"
        case numReplacedSafebrowsing = "num_replaced_safebrowsing"
        case avgProcessingTime = "avg_processing_time"
    }
    
    var blockPercentage: Double {
        guard numDnsQueries > 0 else { return 0.0 }
        return (Double(numBlockedFiltering) / Double(numDnsQueries)) * 100
    }
}
