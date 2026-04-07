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
    func testUpdateStockChangesPriceAndPreviousPrice() async throws {
        setUp()
        
        let update = PriceUpdate(symbol: "AAPL", price: 155, lastUpdated: Date(timeIntervalSince1970: 3000))
        store.update(update)
        
        guard let updatedStock = store.stock(for: "AAPL") else {
            throw TestError("Updated stock not found")
        }
        
        #expect(updatedStock.price == 155, "Price should update")
        #expect(updatedStock.previousPrice == 150, "Previous price should be preserved")
        #expect(updatedStock.lastUpdated == Date(timeIntervalSince1970: 3000), "lastUpdated should match update")
    }

    @Test
    func testSortByPrice() async throws {
        setUp()
        
        store.debounceDuration = 0
        store.sortType = .price
        await store.sortTask?.value
        
        let symbols = store.stocks.map(\.symbol)
        #expect(symbols == ["GOOG", "MSFT", "AAPL"], "Sorting by price should put highest first")
    }

    @Test
    func testSortByChange() async throws {
        setUp()
        
        store.debounceDuration = 0
        store.sortType = .change
        await store.sortTask?.value
        
        let symbols = store.stocks.map(\.symbol)
        #expect(symbols == ["GOOG", "AAPL", "MSFT"], "Sorting by largest change first")
    }

    @Test
    func testSortByUpdated() async throws {
        setUp()
        
        store.debounceDuration = 0
        store.sortType = .updated
        await store.sortTask?.value
        
        let symbols = store.stocks.map(\.symbol)
        #expect(symbols == ["GOOG", "MSFT", "AAPL"], "Sorting by latest update first")
    }
    
    @Test
    func testStableSortByPriceForEqualValues() async throws {
        setUp()
        
        // Update AAPL and MSFT to have the same price using the public `update` method
        store.update(PriceUpdate(
            symbol: "AAPL",
            price: 300,
            lastUpdated: Date(timeIntervalSince1970: 1000)
        ))
        
        store.update(PriceUpdate(
            symbol: "MSFT",
            price: 300,
            lastUpdated: Date(timeIntervalSince1970: 1500)
        ))
        
        // Set sort type
        store.debounceDuration = 0
        store.sortType = .price
        await store.sortTask?.value
        
        // Verify order: GOOG highest, then tie broken by symbol
        let symbols = store.stocks.map(\.symbol)
        #expect(symbols[0] == "GOOG", "Highest price first")
        #expect(symbols[1] < symbols[2], "Tie broken by symbol for stability")
    }
}

// MARK: - TestError
struct TestError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}
