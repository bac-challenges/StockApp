//
//  MockStockFetchingService.swift
//  StocksAppTests
//
//  Created by Codex on 09/04/2026.
//

import Foundation
@testable import StocksApp

@MainActor
final class TestStockFetchingService: StockFetchingProtocol {
    var stocksToReturn: [Stock]
    var fetchCount = 0

    init(stocksToReturn: [Stock] = StockFixtures.sampleStocks) {
        self.stocksToReturn = stocksToReturn
    }

    func fetchStocks() async throws -> [Stock] {
        fetchCount += 1
        return stocksToReturn
    }
}
