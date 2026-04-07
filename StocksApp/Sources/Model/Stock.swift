//
//  Stock.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import Foundation

struct Stock: Identifiable {
    
    let symbol: String
    let description: String
    
    let price: Double
    let previousPrice: Double
    
    var id: String {
        symbol
    }
}

#if DEBUG
extension Stock {
    static var sample: Stock {
        Stock(
            symbol: "AAPL",
            description: "Apple Inc.",
            price: 150,
            previousPrice: 145
        )
    }
}
#endif
