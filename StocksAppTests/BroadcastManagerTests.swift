//
//  BroadcastManagerTests.swift
//  StocksAppTests
//
//  Created by emile on 08/04/2026.
//

import Testing
import Foundation
import Combine
@testable import StocksApp

@MainActor
final class BroadcastManagerTests {

    var service: MockStreamingService!
    var store: MockStockStore!
    
    func setUp() {
        service = MockStreamingService()
        store = MockStockStore()
    }
    
    final class MockStockStore: StockStoreProtocol {
        let stocks: [Stock] = []
        private var storage: [String: Stock] = [:]
        func set(_ stock: Stock) { storage[stock.symbol] = stock }
        func stock(for symbol: String) -> Stock? { storage[symbol] }
        func update(_ update: PriceMessage) {}
    }

    @Test
    func testStartDoesNothingIfAlreadyRunning() async throws {
        setUp()
        
        store.set(Stock(symbol: "AAPL", description: "", price: 100, previousPrice: 90, lastUpdated: Date()))
        
        let manager = BroadcastManager(
            service: service,
            stockStore: store,
            broadcastInterval: 1_000_000,
            symbols: ["AAPL"],
            priceGenerator: { $0.price + 1 }
        )
        
        manager.start()
        manager.start()
        
        await manager.broadcastNextForTest()
        await manager.broadcastNextForTest()
        
        #expect(service.sentMessages.count == 2, "Should only have two broadcasts despite two start calls")
    }
    
    @Test
    func testStopCancelsTask() async throws {
        setUp()
        
        store.set(Stock(symbol: "AAPL", description: "", price: 100, previousPrice: 90, lastUpdated: Date()))
        
        let manager = BroadcastManager(
            service: service,
            stockStore: store,
            broadcastInterval: 10_000_000,
            symbols: ["AAPL"],
            priceGenerator: { $0.price + 1 }
        )
        
        manager.start()
        
        try? await Task.sleep(nanoseconds: 20_000_000)
        
        manager.stop()
        
        let messageCountAfterStop = service.sentMessages.count
        
        try? await Task.sleep(nanoseconds: 20_000_000)
        
        #expect(service.sentMessages.count == messageCountAfterStop, "No new messages should be sent after stop")
    }
    
    @Test
    func testNoBroadcastWhenSymbolsEmpty() async throws {
        setUp()
        
        let manager = BroadcastManager(
            service: service,
            stockStore: store,
            broadcastInterval: 1_000_000,
            symbols: [],
            priceGenerator: { $0.price + 1 }
        )
        
        manager.start()
        try? await Task.sleep(nanoseconds: 5_000_000)
        manager.stop()
        
        #expect(service.sentMessages.isEmpty, "No messages should be sent if symbols array is empty")
    }
    
    @Test
    func testNoBroadcastWhenStockMissing() async throws {
        setUp()
        
        let manager = BroadcastManager(
            service: service,
            stockStore: store,
            broadcastInterval: 1_000_000,
            symbols: ["AAPL"],
            priceGenerator: { $0.price + 1 }
        )
        
        manager.start()
        try? await Task.sleep(nanoseconds: 5_000_000)
        manager.stop()
        
        #expect(service.sentMessages.isEmpty, "No messages should be sent if stock is missing")
    }
    
    @Test
    func testNoBroadcastWhenPriceChangeTooSmall() async throws {
        setUp()
        
        store.set(Stock(symbol: "AAPL", description: "", price: 100, previousPrice: 90, lastUpdated: Date()))
        
        let manager = BroadcastManager(
            service: service,
            stockStore: store,
            broadcastInterval: 1_000_000,
            symbols: ["AAPL"],
            priceGenerator: { $0.price + 0.005 } // below 0.01 threshold
        )
        
        manager.start()
        try? await Task.sleep(nanoseconds: 5_000_000)
        manager.stop()
        
        #expect(service.sentMessages.isEmpty, "No messages should be sent if price change is too small")
    }
    
    @Test
    func testBroadcastsWhenPriceChangesSignificantly() async throws {
        setUp()
        
        store.set(Stock(symbol: "AAPL", description: "", price: 100, previousPrice: 90, lastUpdated: Date()))
        
        let manager = BroadcastManager(
            service: service,
            stockStore: store,
            broadcastInterval: 1_000_000,
            symbols: ["AAPL"],
            priceGenerator: { $0.price + 1.0 }
        )
        
        manager.start()
        try? await Task.sleep(nanoseconds: 5_000_000)
        manager.stop()
        
        #expect(!service.sentMessages.isEmpty, "Message should be sent if price change exceeds threshold")
    }
    
    @Test
    func testCyclesThroughSymbols() async throws {
        setUp()
        
        store.set(Stock(symbol: "AAPL", description: "", price: 100, previousPrice: 90, lastUpdated: Date()))
        store.set(Stock(symbol: "GOOG", description: "", price: 200, previousPrice: 90, lastUpdated: Date()))
        
        let manager = BroadcastManager(
            service: service,
            stockStore: store,
            broadcastInterval: 1_000_000,
            symbols: ["AAPL", "GOOG"],
            priceGenerator: { $0.price + 1 }
        )
        
        // Manually trigger two broadcasts
        await manager.broadcastNextForTest()
        await manager.broadcastNextForTest()
        
        #expect(service.sentMessages.count == 2, "Should cycle through symbols")
        #expect(service.sentMessages[0].contains("AAPL"), "First broadcast should be AAPL")
        #expect(service.sentMessages[1].contains("GOOG"), "Second broadcast should be GOOG")
    }
}
