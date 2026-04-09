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
    
    let lastUpdated: Date
    
    var id: String {
        symbol
    }

    /// Difference between current and previous price, rounded to 2 decimals
    var change: Double {
        let priceDecimal = Decimal(string: String(price), locale: Locale(identifier: "en_US_POSIX")) ?? Decimal(price)
        let previousPriceDecimal = Decimal(string: String(previousPrice), locale: Locale(identifier: "en_US_POSIX")) ?? Decimal(previousPrice)
        let changeDecimal = priceDecimal - previousPriceDecimal

        var roundedDecimal = Decimal()
        var workingDecimal = changeDecimal
        NSDecimalRound(&roundedDecimal, &workingDecimal, 2, .plain)
        return NSDecimalNumber(decimal: roundedDecimal).doubleValue
    }
    
    /// Indicates if the stock went up or stayed flat
    var isUp: Bool {
        change >= 0
    }
}

// MARK: - Static Data
extension Stock {
    static nonisolated let symbols: [String] = [
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
                previousPrice: Double.random(in: 100...500).rounded(toPlaces: 2),
                lastUpdated: Date(timeIntervalSince1970: Double(index * 1000))
            )
        }
    }
    
    static var sample: Stock {
        Stock(
            symbol: "AAPL",
            description: "Apple Inc.",
            price: 150,
            previousPrice: 145,
            lastUpdated: Date()
        )
    }
}
#endif
