//
//  BroadcastManagerTests.swift
//  StocksAppTests
//
//  Created by emile on 08/04/2026.
//

import Testing
import Foundation
@testable import StocksApp

@MainActor
final class BroadcastManagerTests {

    var service: MockStreamingService!
    var stocksBySymbol: [String: Stock]!
    
    func setUp() {
        service = MockStreamingService()
        stocksBySymbol = [:]
    }

    func lookupStock(_ symbol: String) -> Stock? {
        stocksBySymbol[symbol]
    }

    @Test
    func testStartDoesNothingIfAlreadyRunning() async throws {
        setUp()
        
        stocksBySymbol["AAPL"] = Stock(symbol: "AAPL", description: "", price: 100, previousPrice: 90, lastUpdated: Date())
        
        let manager = BroadcastManager(
            service: service,
            stockLookup: lookupStock,
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
        
        stocksBySymbol["AAPL"] = Stock(symbol: "AAPL", description: "", price: 100, previousPrice: 90, lastUpdated: Date())
        
        let manager = BroadcastManager(
            service: service,
            stockLookup: lookupStock,
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
            stockLookup: lookupStock,
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
            stockLookup: lookupStock,
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
        
        stocksBySymbol["AAPL"] = Stock(symbol: "AAPL", description: "", price: 100, previousPrice: 90, lastUpdated: Date())
        
        let manager = BroadcastManager(
            service: service,
            stockLookup: lookupStock,
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
    func testNoBroadcastWhenPriceChangeIsExactlyThreshold() async throws {
        setUp()

        stocksBySymbol["AAPL"] = StockFixtures.stock(price: 100, previousPrice: 90)

        let manager = BroadcastManager(
            service: service,
            stockLookup: lookupStock,
            broadcastInterval: 1_000_000,
            symbols: ["AAPL"],
            priceGenerator: { stock in stock.price + 0.01 }
        )

        await manager.broadcastNextForTest()

        #expect(service.sentMessages.isEmpty, "No message should be sent when delta is exactly 0.01")
    }
    
    @Test
    func testBroadcastsWhenPriceChangesSignificantly() async throws {
        setUp()
        
        stocksBySymbol["AAPL"] = Stock(symbol: "AAPL", description: "", price: 100, previousPrice: 90, lastUpdated: Date())
        
        let manager = BroadcastManager(
            service: service,
            stockLookup: lookupStock,
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
        
        stocksBySymbol["AAPL"] = Stock(symbol: "AAPL", description: "", price: 100, previousPrice: 90, lastUpdated: Date())
        stocksBySymbol["GOOG"] = Stock(symbol: "GOOG", description: "", price: 200, previousPrice: 90, lastUpdated: Date())
        
        let manager = BroadcastManager(
            service: service,
            stockLookup: lookupStock,
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

    @Test
    func testCyclesBackToFirstSymbolAfterWraparound() async throws {
        setUp()

        stocksBySymbol["AAPL"] = StockFixtures.stock(symbol: "AAPL", price: 100, previousPrice: 90)
        stocksBySymbol["GOOG"] = StockFixtures.stock(symbol: "GOOG", description: "Google", price: 200, previousPrice: 190)

        let manager = BroadcastManager(
            service: service,
            stockLookup: lookupStock,
            broadcastInterval: 1_000_000,
            symbols: ["AAPL", "GOOG"],
            priceGenerator: { $0.price + 1 }
        )

        await manager.broadcastNextForTest()
        await manager.broadcastNextForTest()
        await manager.broadcastNextForTest()

        #expect(service.sentMessages.count == 3)
        #expect(service.sentMessages[2].contains("AAPL"), "Third broadcast should wrap back to AAPL")
    }

    @Test
    func testMissingStockDoesNotAdvanceSymbolIndex() async throws {
        setUp()

        stocksBySymbol["GOOG"] = StockFixtures.stock(symbol: "GOOG", description: "Google", price: 200, previousPrice: 190)

        let manager = BroadcastManager(
            service: service,
            stockLookup: lookupStock,
            broadcastInterval: 1_000_000,
            symbols: ["AAPL", "GOOG"],
            priceGenerator: { $0.price + 1 }
        )

        await manager.broadcastNextForTest()
        await manager.broadcastNextForTest()

        #expect(service.sentMessages.isEmpty, "Missing first symbol should prevent index advancement with current behavior")
    }

    @Test
    func testBroadcastMessagePayloadParsesCorrectly() async throws {
        setUp()

        stocksBySymbol["AAPL"] = StockFixtures.stock(symbol: "AAPL", price: 100, previousPrice: 90)

        let manager = BroadcastManager(
            service: service,
            stockLookup: lookupStock,
            broadcastInterval: 1_000_000,
            symbols: ["AAPL"],
            priceGenerator: { _ in 105 }
        )

        await manager.broadcastNextForTest()

        guard let raw = service.sentMessages.first,
              let message = PriceMessage.parse(raw) else {
            throw TestError("Expected a valid emitted price message")
        }

        #expect(message.symbol == "AAPL")
        #expect(message.price == 105)
        #expect(message.timestamp > 0)
    }
}
