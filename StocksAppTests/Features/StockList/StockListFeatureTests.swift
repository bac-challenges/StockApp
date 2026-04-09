//
//  StockListFeatureTests.swift
//  StocksAppTests
//
//  Created by emile on 07/04/2026.
//

import Testing
import Foundation
@testable import StocksApp

@MainActor
final class StockListFeatureTests {

    @Test
    func testInitialStockCount() async throws {
        let state = StocksFeature.State(stocks: StockFixtures.sampleStocks)
        #expect(state.stocks.count == 3, "State should initialize with 3 stocks")
    }
    
    @Test
    func testUpdateStockChangesPriceAndPreviousPrice() async throws {
        let update = PriceMessage(symbol: "AAPL",
                                  price: 155,
                                  timestamp: Date(timeIntervalSince1970: 3000)
                                                .timeIntervalSince1970)
        let updatedStocks = StockSorting.updatedStocks(StockFixtures.sampleStocks, with: update)
        
        guard let updatedStock = updatedStocks.first(where: { $0.symbol == "AAPL" }) else {
            throw TestError("Updated stock not found")
        }
        
        #expect(updatedStock.price == 155, "Price should update")
        #expect(updatedStock.previousPrice == 150, "Previous price should be preserved")
        #expect(updatedStock.lastUpdated == Date(timeIntervalSince1970: 3000), "lastUpdated should match update")
    }

    @Test
    func testSortByPrice() async throws {
        let symbols = StockSorting.sortedStocks(StockFixtures.sampleStocks, by: .price).map(\.symbol)
        #expect(symbols == ["GOOG", "MSFT", "AAPL"], "Sorting by price should put highest first")
    }

    @Test
    func testSortByChange() async throws {
        let symbols = StockSorting.sortedStocks(StockFixtures.sampleStocks, by: .change).map(\.symbol)
        #expect(symbols == ["GOOG", "AAPL", "MSFT"], "Sorting by largest change first")
    }

    @Test
    func testSortByUpdated() async throws {
        let symbols = StockSorting.sortedStocks(StockFixtures.sampleStocks, by: .updated).map(\.symbol)
        #expect(symbols == ["GOOG", "MSFT", "AAPL"], "Sorting by latest update first")
    }
    
    @Test
    func testStableSortByPriceForEqualValues() async throws {
        let updatedOnce = StockSorting.updatedStocks(StockFixtures.sampleStocks, with: PriceMessage(
            symbol: "AAPL",
            price: 300,
            timestamp: Date(timeIntervalSince1970: 1000).timeIntervalSince1970
        ))
        
        let updatedStocks = StockSorting.updatedStocks(updatedOnce, with: PriceMessage(
            symbol: "MSFT",
            price: 300,
            timestamp: Date(timeIntervalSince1970: 1500).timeIntervalSince1970
        ))
        
        let symbols = StockSorting.sortedStocks(updatedStocks, by: .price).map(\.symbol)
        #expect(symbols[0] == "GOOG", "Highest price first")
        #expect(symbols[1] < symbols[2], "Tie broken by symbol for stability")
    }

    @Test
    func testReducerUpdatesStateFromIncomingMessage() async throws {
        var state = StocksFeature.State(stocks: StockFixtures.sampleStocks)
        let commands = StocksFeature.reduce(
            state: &state,
            action: .receivedMessage("AAPL|155|3000")
        )

        #expect(commands.count == 1, "Incoming message should produce a single follow-up command")
        if case .scheduleSort = commands[0] {
            #expect(true)
        } else {
            Issue.record("Incoming message should request a resort")
        }
        #expect(state.stock(for: "AAPL")?.price == 155, "Reducer should update the matching stock")
    }

    @Test
    func testReducerStartTransitionsToRunningAndEmitsCommands() async throws {
        var state = StocksFeature.State(stocks: StockFixtures.sampleStocks)

        let commands = StocksFeature.reduce(state: &state, action: .start)

        #expect(state.lifecycle == .running)
        #expect(commands.count == 2)
        if case .connect = commands[0] {
            #expect(true)
        } else {
            Issue.record("First command should connect")
        }
        if case .startBroadcasting = commands[1] {
            #expect(true)
        } else {
            Issue.record("Second command should start broadcasting")
        }
    }

    @Test
    func testReducerStartIsNoOpWhenAlreadyRunning() async throws {
        var state = StocksFeature.State(
            connectionState: .connected,
            lifecycle: .running,
            stocks: StockFixtures.sampleStocks,
            sortType: .price
        )

        let commands = StocksFeature.reduce(state: &state, action: .start)

        #expect(commands.isEmpty)
        #expect(state.lifecycle == .running)
    }

    @Test
    func testReducerStopTransitionsToStoppedAndEmitsCommands() async throws {
        var state = StocksFeature.State(
            connectionState: .connected,
            lifecycle: .running,
            stocks: StockFixtures.sampleStocks,
            sortType: .price
        )

        let commands = StocksFeature.reduce(state: &state, action: .stop)

        #expect(state.lifecycle == .stopped)
        #expect(commands.count == 2)
        if case .stopBroadcasting = commands[0] {
            #expect(true)
        } else {
            Issue.record("First command should stop broadcasting")
        }
        if case .disconnect = commands[1] {
            #expect(true)
        } else {
            Issue.record("Second command should disconnect")
        }
    }

    @Test
    func testReducerStartStopButtonTogglesFromStopped() async throws {
        var state = StocksFeature.State(stocks: StockFixtures.sampleStocks)

        let commands = StocksFeature.reduce(state: &state, action: .startStopButtonTapped)

        #expect(state.lifecycle == .running)
        #expect(commands.count == 2)
    }

    @Test
    func testReducerStartStopButtonTogglesFromRunning() async throws {
        var state = StocksFeature.State(
            connectionState: .connected,
            lifecycle: .running,
            stocks: StockFixtures.sampleStocks,
            sortType: .price
        )

        let commands = StocksFeature.reduce(state: &state, action: .startStopButtonTapped)

        #expect(state.lifecycle == .stopped)
        #expect(commands.count == 2)
    }

    @Test
    func testReducerSortSelectedUpdatesSortTypeAndSchedulesSort() async throws {
        var state = StocksFeature.State(stocks: StockFixtures.sampleStocks)

        let commands = StocksFeature.reduce(state: &state, action: .sortSelected(.updated))

        #expect(state.sortType == .updated)
        #expect(commands.count == 1)
        if case .scheduleSort = commands[0] {
            #expect(true)
        } else {
            Issue.record("Sort selection should schedule sorting")
        }
    }

    @Test
    func testReducerInvalidMessageDoesNothing() async throws {
        var state = StocksFeature.State(stocks: StockFixtures.sampleStocks)
        let originalStocks = state.stocks

        let commands = StocksFeature.reduce(state: &state, action: .receivedMessage("invalid"))

        #expect(commands.isEmpty)
        #expect(state.stocks == originalStocks)
    }

    @Test
    func testReducerConnectionStateChangedOnlyUpdatesConnectionState() async throws {
        var state = StocksFeature.State(stocks: StockFixtures.sampleStocks)
        let originalStocks = state.stocks

        let commands = StocksFeature.reduce(state: &state, action: .connectionStateChanged(.connected))

        #expect(commands.isEmpty)
        #expect(state.connectionState == .connected)
        #expect(state.stocks == originalStocks)
    }

    @Test
    func testReducerSortDebounceElapsedSortsStocks() async throws {
        var state = StocksFeature.State(stocks: StockFixtures.sampleStocks, sortType: .updated)

        let commands = StocksFeature.reduce(state: &state, action: .sortDebounceElapsed)

        #expect(commands.isEmpty)
        #expect(state.stocks.map(\.symbol) == ["GOOG", "MSFT", "AAPL"])
    }

    @Test
    func testReducerSortDebounceElapsedHandlesEmptyStocks() async throws {
        var state = StocksFeature.State(stocks: [])

        let commands = StocksFeature.reduce(state: &state, action: .sortDebounceElapsed)

        #expect(commands.isEmpty)
        #expect(state.stocks.isEmpty)
    }
}
