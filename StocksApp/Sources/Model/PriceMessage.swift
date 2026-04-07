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
