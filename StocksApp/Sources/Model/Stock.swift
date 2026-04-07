//
//  Stock.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import Foundation

struct Stock: Identifiable, Hashable {
    
    let symbol: String
    let description: String
    
    let price: Double
    let previousPrice: Double
    
    var id: String {
        symbol
    }

    var change: Double {
        (price - previousPrice).rounded(toPlaces: 2)
    }
    
    var isUp: Bool {
        change >= 0
    }
}

// MARK: - Helpers
extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - Static Data
extension Stock {
    
    static let symbols: [String] = [
        "AAPL","GOOG","TSLA","AMZN","MSFT",
        "NVDA","META","NFLX","ORCL","INTC",
        "AMD","IBM","UBER","SHOP","SQ",
        "PYPL","BABA","SONY","CRM","ADBE",
        "CSCO","QCOM","SAP","TXN","AVGO"
    ]
}

#if DEBUG
extension Stock {
    
    static var stocks: [Stock] {
        Stock.symbols.enumerated().map { index, symbol in
            Stock(
                symbol: symbol,
                description: "Description for \(symbol)",
                price: Double.random(in: 100...500).rounded(toPlaces: 2),
                previousPrice: Double.random(in: 100...500).rounded(toPlaces: 2)
            )
        }
    }
    
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
