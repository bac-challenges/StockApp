//
//  AppStoreTests.swift
//  StocksAppTests
//
//  Created by emile on 08/04/2026.
//

import Testing
import Foundation
@testable import StocksApp

@MainActor
final class AppStoreTests {

    var service: MockStreamingService!
    var stockFetchingService: TestStockFetchingService!
    var store: AppStore!

    func setUp() {
        service = MockStreamingService()
        stockFetchingService = TestStockFetchingService(stocksToReturn: Stock.stocks)
        store = AppStore(
            priceBroadcastService: service,
            stockFetchingService: stockFetchingService,
            initialStocks: Stock.stocks,
            broadcastInterval: 0,
            sortDebounceDuration: 0,
            priceGenerator: { $0.price + 1 }
        )
    }

    @Test
    func testInitialState() async throws {
        setUp()
        #expect(store.isRunning == false, "Initial lifecycle should be stopped")
        #expect(store.stocks.count == Stock.stocks.count, "Stocks should initialize from Stock.stocks")
        #expect(store.connectionState == .disconnected, "Initial connection state should be disconnected")
    }

    @Test
    func testStartChangesLifecycleAndConnects() async throws {
        setUp()
        store.send(.start)
        #expect(store.isRunning == true, "Lifecycle should be running after start")
        #expect(service.didConnect == true, "Service should connect on start")
        #expect(store.connectionState == .connected, "Connection state should update to connected")
    }

    @Test
    func testStopChangesLifecycleAndDisconnects() async throws {
        setUp()
        store.send(.start)
        store.send(.stop)
        #expect(store.isRunning == false, "Lifecycle should be stopped after stop")
        #expect(service.didDisconnect == true, "Service should disconnect on stop")
        #expect(store.connectionState == .disconnected, "Connection state should update to disconnected")
    }

    @Test
    func testHandleIncomingMessageUpdatesStock() async throws {
        setUp()
        
        let stock = store.stocks.first!
        let oldPrice = stock.price
        let timestamp = Date(timeIntervalSince1970: 3000)
        let updateMessage = "\(stock.symbol)|\(oldPrice + 10)|\(timestamp.timeIntervalSince1970)"
        
        service.send(updateMessage)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        guard let updatedStock = store.stocks.first(where: { $0.symbol == stock.symbol }) else {
            throw TestError("Updated stock not found")
        }
        
        #expect(updatedStock.price == oldPrice + 10, "Price should update from message")
        #expect(updatedStock.previousPrice == oldPrice, "Previous price should preserve old value")
        
        let diff = abs(updatedStock.lastUpdated.timeIntervalSince1970 - timestamp.timeIntervalSince1970)
        #expect(diff < 0.001, "lastUpdated should match message timestamp")
    }

    @Test
    func testSortSelectionDebouncesAndResortsStocks() async throws {
        service = MockStreamingService()
        stockFetchingService = TestStockFetchingService()
        store = AppStore(
            priceBroadcastService: service,
            stockFetchingService: stockFetchingService,
            initialStocks: StockFixtures.sampleStocks,
            broadcastInterval: 0,
            sortDebounceDuration: 10_000_000,
            priceGenerator: { $0.price + 1 }
        )

        store.send(.sortSelected(.updated))
        try? await Task.sleep(nanoseconds: 30_000_000)

        #expect(store.stocks.map(\.symbol) == ["GOOG", "MSFT", "AAPL"])
    }

    @Test
    func testSortSelectionCancelsPreviousDebouncedSort() async throws {
        service = MockStreamingService()
        stockFetchingService = TestStockFetchingService()
        store = AppStore(
            priceBroadcastService: service,
            stockFetchingService: stockFetchingService,
            initialStocks: StockFixtures.sampleStocks,
            broadcastInterval: 0,
            sortDebounceDuration: 20_000_000,
            priceGenerator: { $0.price + 1 }
        )

        store.send(.sortSelected(.updated))
        store.send(.sortSelected(.change))

        try? await Task.sleep(nanoseconds: 80_000_000)

        #expect(store.stocks.map(\.symbol) == ["GOOG", "AAPL", "MSFT"])
        #expect(store.state.sortType == .change)
    }

    @Test
    func testMultipleMessagesUpdateCorrectStocks() async throws {
        setUp()

        service.send("AAPL|200|3000")
        service.send("GOOG|2900|4000")
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(store.stock(for: "AAPL")?.price == 200)
        #expect(store.stock(for: "GOOG")?.price == 2900)
    }

    @Test
    func testStartStopButtonTappedStartsAndStopsStore() async throws {
        setUp()

        store.send(.startStopButtonTapped)
        #expect(store.isRunning)
        #expect(service.didConnect)

        store.send(.startStopButtonTapped)
        #expect(!store.isRunning)
        #expect(service.didDisconnect)
    }

    @Test
    func testStockLookupReturnsMatchingStock() async throws {
        setUp()

        let stock = store.stock(for: "AAPL")

        #expect(stock?.symbol == "AAPL")
    }

    @Test
    func testConnectionStatePublisherUpdatesStoreState() async throws {
        setUp()

        service.connect()
        try? await Task.sleep(nanoseconds: 20_000_000)
        #expect(store.connectionState == .connected)

        service.disconnect()
        try? await Task.sleep(nanoseconds: 20_000_000)
        #expect(store.connectionState == .disconnected)
    }

    @Test
    func testBootstrapFetchesStocksAndStartsStreaming() async throws {
        service = MockStreamingService()
        stockFetchingService = TestStockFetchingService(stocksToReturn: StockFixtures.sampleStocks)
        store = AppStore(
            priceBroadcastService: service,
            stockFetchingService: stockFetchingService,
            initialStocks: [],
            broadcastInterval: 0,
            sortDebounceDuration: 0,
            priceGenerator: { $0.price + 1 }
        )

        await store.bootstrap()

        #expect(stockFetchingService.fetchCount == 1)
        #expect(store.stocks.map(\.symbol) == ["GOOG", "MSFT", "AAPL"])
        #expect(store.isRunning)
        #expect(service.didConnect)
    }

    @Test
    func testBootstrapRunsOnlyOnce() async throws {
        setUp()

        await store.bootstrap()
        await store.bootstrap()

        #expect(stockFetchingService.fetchCount == 1)
    }

    @Test
    func testBootstrapFailureDoesNotStartStreamingAndAllowsRetry() async throws {
        service = MockStreamingService()
        stockFetchingService = TestStockFetchingService(stocksToReturn: StockFixtures.sampleStocks)
        stockFetchingService.errorToThrow = TestError("REST failure")
        store = AppStore(
            priceBroadcastService: service,
            stockFetchingService: stockFetchingService,
            initialStocks: [],
            broadcastInterval: 0,
            sortDebounceDuration: 0,
            priceGenerator: { $0.price + 1 }
        )

        await store.bootstrap()

        #expect(stockFetchingService.fetchCount == 1)
        #expect(!store.isBootstrapping)
        #expect(!store.isRunning)
        #expect(!service.didConnect)
        #expect(store.stocks.isEmpty)

        stockFetchingService.errorToThrow = nil
        await store.bootstrap()

        #expect(stockFetchingService.fetchCount == 2)
        #expect(store.isRunning)
        #expect(service.didConnect)
        #expect(!store.stocks.isEmpty)
    }

    @Test
    func testBootstrapWithEmptyResponseKeepsListEmptyAndStartsSafely() async throws {
        service = MockStreamingService()
        stockFetchingService = TestStockFetchingService(stocksToReturn: [])
        store = AppStore(
            priceBroadcastService: service,
            stockFetchingService: stockFetchingService,
            initialStocks: [],
            broadcastInterval: 0,
            sortDebounceDuration: 0,
            priceGenerator: { $0.price + 1 }
        )

        await store.bootstrap()

        #expect(stockFetchingService.fetchCount == 1)
        #expect(store.stocks.isEmpty)
        #expect(store.isRunning)
        #expect(service.didConnect)
    }

    @Test
    func testBootstrapDeduplicatesBroadcastSymbolsFromFetchedStocks() async throws {
        service = MockStreamingService()
        stockFetchingService = TestStockFetchingService(stocksToReturn: [
            StockFixtures.stock(symbol: "AAPL", description: "Apple", price: 100, previousPrice: 99),
            StockFixtures.stock(symbol: "AAPL", description: "Apple Duplicate", price: 101, previousPrice: 100),
            StockFixtures.stock(symbol: "GOOG", description: "Google", price: 200, previousPrice: 199),
        ])
        store = AppStore(
            priceBroadcastService: service,
            stockFetchingService: stockFetchingService,
            initialStocks: [],
            broadcastInterval: 1_000_000,
            sortDebounceDuration: 0,
            priceGenerator: { $0.price + 1 }
        )

        await store.bootstrap()
        try? await Task.sleep(nanoseconds: 20_000_000)

        let emittedSymbols = service.sentMessages.compactMap { PriceMessage.parse($0)?.symbol }
        let uniqueEmittedSymbols = Set(emittedSymbols)
        let expectedSymbols: Set<String> = ["AAPL", "GOOG"]

        #expect(store.stocks.count == 3)
        #expect(uniqueEmittedSymbols.isSubset(of: expectedSymbols))
        #expect(uniqueEmittedSymbols.contains("AAPL"))
        #expect(uniqueEmittedSymbols.contains("GOOG"))
    }

    @Test
    func testBootstrapThenStreamingUpdatesFetchedStocks() async throws {
        service = MockStreamingService()
        stockFetchingService = TestStockFetchingService(stocksToReturn: StockFixtures.sampleStocks)
        store = AppStore(
            priceBroadcastService: service,
            stockFetchingService: stockFetchingService,
            initialStocks: [],
            broadcastInterval: 1_000_000,
            sortDebounceDuration: 0,
            priceGenerator: { $0.price + 1 }
        )

        await store.bootstrap()
        let originalAAPLPrice = store.stock(for: "AAPL")?.price
        let originalGOOGPrice = store.stock(for: "GOOG")?.price
        try? await Task.sleep(nanoseconds: 20_000_000)

        let aaplChanged = store.stock(for: "AAPL")?.price != originalAAPLPrice
        let googChanged = store.stock(for: "GOOG")?.price != originalGOOGPrice

        #expect(!service.sentMessages.isEmpty)
        #expect(aaplChanged || googChanged, "Streaming should update at least one fetched stock")
    }

    @Test
    func testStartDoesNothingIfAlreadyRunning() async throws {
        setUp()
        store.send(.start)
        let initialConnect = service.didConnect
        store.send(.start)
        #expect(service.didConnect == initialConnect, "Repeated start should not reconnect")
    }

    @Test
    func testStopDoesNothingIfAlreadyStopped() async throws {
        setUp()
        store.send(.stop)
        #expect(service.didDisconnect == false, "Stop on already stopped state should not disconnect")
    }
}
