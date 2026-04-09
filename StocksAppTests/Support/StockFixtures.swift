//
//  StockFixtures.swift
//  StocksAppTests
//
//  Created by Codex on 09/04/2026.
//

import Foundation
@testable import StocksApp

enum StockFixtures {
    static let sampleStocks: [Stock] = [
        Stock(
            symbol: "AAPL",
            description: "Apple",
            price: 150,
            previousPrice: 145,
            lastUpdated: Date(timeIntervalSince1970: 1000)
        ),
        Stock(
            symbol: "GOOG",
            description: "Google",
            price: 2800,
            previousPrice: 2790,
            lastUpdated: Date(timeIntervalSince1970: 2000)
        ),
        Stock(
            symbol: "MSFT",
            description: "Microsoft",
            price: 300,
            previousPrice: 295,
            lastUpdated: Date(timeIntervalSince1970: 1500)
        )
    ]

    static func stock(
        symbol: String = "AAPL",
        description: String = "Apple",
        price: Double = 100,
        previousPrice: Double = 90,
        lastUpdated: Date = Date(timeIntervalSince1970: 1000)
    ) -> Stock {
        Stock(
            symbol: symbol,
            description: description,
            price: price,
            previousPrice: previousPrice,
            lastUpdated: lastUpdated
        )
    }
}
