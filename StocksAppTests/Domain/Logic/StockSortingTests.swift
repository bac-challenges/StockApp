//
//  StockSortingTests.swift
//  StocksAppTests
//
//  Created by Codex on 09/04/2026.
//

import Foundation
import Testing
@testable import StocksApp

@MainActor
final class StockSortingTests {
    @Test
    func testPriceSortBreaksTiesBySymbol() async throws {
        let stocks = [
            StockFixtures.stock(symbol: "MSFT", price: 300, previousPrice: 290),
            StockFixtures.stock(symbol: "AAPL", price: 300, previousPrice: 280),
        ]

        let sorted = StockSorting.sortedStocks(stocks, by: .price)

        #expect(sorted.map(\.symbol) == ["AAPL", "MSFT"])
    }

    @Test
    func testChangeSortBreaksTiesBySymbol() async throws {
        let stocks = [
            StockFixtures.stock(symbol: "MSFT", price: 110, previousPrice: 100),
            StockFixtures.stock(symbol: "AAPL", price: 90, previousPrice: 100),
        ]

        let sorted = StockSorting.sortedStocks(stocks, by: .change)

        #expect(sorted.map(\.symbol) == ["AAPL", "MSFT"])
    }

    @Test
    func testUpdatedSortBreaksTiesBySymbol() async throws {
        let timestamp = Date(timeIntervalSince1970: 1000)
        let stocks = [
            StockFixtures.stock(symbol: "MSFT", lastUpdated: timestamp),
            StockFixtures.stock(symbol: "AAPL", lastUpdated: timestamp),
        ]

        let sorted = StockSorting.sortedStocks(stocks, by: .updated)

        #expect(sorted.map(\.symbol) == ["AAPL", "MSFT"])
    }

    @Test
    func testUpdatedStocksLeavesUnknownSymbolsUnchanged() async throws {
        let updated = StockSorting.updatedStocks(
            StockFixtures.sampleStocks,
            with: PriceMessage(symbol: "NFLX", price: 999, timestamp: 3000)
        )

        #expect(updated == StockFixtures.sampleStocks)
    }
}
