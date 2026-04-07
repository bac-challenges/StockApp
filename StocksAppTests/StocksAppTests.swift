//
//  StocksAppTests.swift
//  StocksAppTests
//
//  Created by emile on 07/04/2026.
//

import Testing
import Foundation
@testable import StocksApp

@MainActor
final class StockStoreTests {

    var store: StockStore!
    var sampleStocks: [Stock]!

    func setUp() {
        sampleStocks = [
            Stock(symbol: "AAPL", description: "Apple", price: 150, previousPrice: 145, lastUpdated: Date(timeIntervalSince1970: 1000)),
            Stock(symbol: "GOOG", description: "Google", price: 2800, previousPrice: 2790, lastUpdated: Date(timeIntervalSince1970: 2000)),
            Stock(symbol: "MSFT", description: "Microsoft", price: 300, previousPrice: 295, lastUpdated: Date(timeIntervalSince1970: 1500))
        ]
        
        store = StockStore(stocks: sampleStocks)
    }

    @Test
    func testInitialStockCount() async throws {
        setUp()
        #expect(store.stocks.count == 3, "StockStore should initialize with 3 stocks")
    }

    @Test
    func testSortByPrice() async throws {
        setUp()
        store.sortType = .price
        
        let symbols = store.stocks.map(\.symbol)
        #expect(symbols == ["GOOG", "MSFT", "AAPL"], "Sorting by price should put highest first")
    }

    @Test
    func testSortByChange() async throws {
        setUp()
        store.sortType = .change
        
        let symbols = store.stocks.map(\.symbol)
        #expect(symbols == ["GOOG", "AAPL", "MSFT"], "Sorting by largest change first")
    }

    @Test
    func testSortByUpdated() async throws {
        setUp()
        store.sortType = .updated
        
        let symbols = store.stocks.map(\.symbol)
        #expect(symbols == ["GOOG", "MSFT", "AAPL"], "Sorting by latest update first")
    }
}

// MARK: - TestError
struct TestError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}
