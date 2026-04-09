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
    var errorToThrow: Error?

    init(stocksToReturn: [Stock] = StockFixtures.sampleStocks) {
        self.stocksToReturn = stocksToReturn
    }

    func fetchStocks() async throws -> [Stock] {
        fetchCount += 1
        if let errorToThrow {
            throw errorToThrow
        }
        return stocksToReturn
    }
}
