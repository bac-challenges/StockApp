//
//  MockStockFetchingService.swift
//  StocksApp
//
//  Created by Codex on 09/04/2026.
//

import Foundation

@MainActor
final class MockStockFetchingService: StockFetchingProtocol {
    func fetchStocks() async throws -> [Stock] {
        try? await Task.sleep(nanoseconds: 300_000_000)

        let descriptions: [String: String] = [
            "AAPL": "Apple Inc.",
            "GOOG": "Alphabet Inc.",
            "TSLA": "Tesla, Inc.",
            "AMZN": "Amazon.com, Inc.",
            "MSFT": "Microsoft Corporation",
            "NVDA": "NVIDIA Corporation",
            "META": "Meta Platforms, Inc.",
            "NFLX": "Netflix, Inc.",
            "ORCL": "Oracle Corporation",
            "INTC": "Intel Corporation"
        ]

        return Stock.symbols.enumerated().map { index, symbol in
            let basePrice = 100.0 + Double(index * 13)
            return Stock(
                symbol: symbol,
                description: descriptions[symbol] ?? "\(symbol) Holdings",
                price: basePrice.rounded(toPlaces: 2),
                previousPrice: (basePrice - 1.25).rounded(toPlaces: 2),
                lastUpdated: Date(timeIntervalSince1970: Double(index * 1000))
            )
        }
    }
}
