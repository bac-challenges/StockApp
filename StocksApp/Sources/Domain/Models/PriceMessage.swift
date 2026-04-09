//
//  PriceMessage.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import Foundation

struct PriceMessage {
    let symbol: String
    let price: Double
    let timestamp: TimeInterval
    
    var raw: String { "\(symbol)|\(price)|\(timestamp)" }
}

extension PriceMessage {
    static func parse(_ text: String) -> PriceMessage? {
        
        let parts = text.split(separator: "|")
        guard parts.count == 3,
              let price = Double(parts[1]),
              let timestamp = TimeInterval(parts[2]) else { return nil }

        return PriceMessage(
            symbol: String(parts[0]),
            price: price,
            timestamp: timestamp
        )
    }
}
