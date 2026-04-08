//
//  AppStateTests.swift
//  StocksAppTests
//
//  Created by emile on 08/04/2026.
//

import Testing
import Foundation
import Combine
@testable import StocksApp

@MainActor
final class AppStateTests {

    var service: MockService!
    var state: AppState!

    func setUp() {
        service = MockService()
        state = AppState(
            service: service,
            broadcastInterval: 0,
            symbols: ["AAPL", "GOOG"],
            priceGenerator: { $0.price + 1 }
        )
    }

    // MARK: - Mocks

    final class MockService: PriceStreamingProtocol {
        private let _messages = PassthroughSubject<String, Never>()
        private let _connectionState = CurrentValueSubject<ConnectionState, Never>(.disconnected)
        
        var messages: AnyPublisher<String, Never> { _messages.eraseToAnyPublisher() }
        var connectionState: AnyPublisher<ConnectionState, Never> { _connectionState.eraseToAnyPublisher() }
        
        private(set) var didConnect = false
        private(set) var didDisconnect = false
        
        func connect() {
            didConnect = true
            _connectionState.send(.connected)
        }
        
        func disconnect() {
            didDisconnect = true
            _connectionState.send(.disconnected)
        }
        
        func send(_ text: String) {
            _messages.send(text)
        }
    }

    // MARK: - Tests

    @Test
    func testInitialState() async throws {
        setUp()
        #expect(state.isRunning == false, "Initial lifecycle should be stopped")
        #expect(state.stocks.count == Stock.stocks.count, "Stocks should initialize from Stock.stocks")
        #expect(state.connectionState == .disconnected, "Initial connection state should be disconnected")
    }

    @Test
    func testStartChangesLifecycleAndConnects() async throws {
        setUp()
        state.start()
        #expect(state.isRunning == true, "Lifecycle should be running after start")
        #expect(service.didConnect == true, "Service should connect on start")
        #expect(state.connectionState == .connected, "Connection state should update to connected")
    }

    @Test
    func testStopChangesLifecycleAndDisconnects() async throws {
        setUp()
        state.start()
        state.stop()
        #expect(state.isRunning == false, "Lifecycle should be stopped after stop")
        #expect(service.didDisconnect == true, "Service should disconnect on stop")
        #expect(state.connectionState == .disconnected, "Connection state should update to disconnected")
    }

    @Test
    func testHandleIncomingMessageUpdatesStock() async throws {
        setUp()
        
        // Pick the first stock
        let stock = state.stocks.first!
        let oldPrice = stock.price
        let timestamp = Date(timeIntervalSince1970: 3000)
        
        // Construct pipe-delimited message
        let updateMessage = "\(stock.symbol)|\(oldPrice + 10)|\(timestamp.timeIntervalSince1970)"
        
        // Send message
        service.send(updateMessage)
        
        // Wait briefly for Combine pipeline
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Fetch updated stock
        guard let updatedStock = state.stocks.first(where: { $0.symbol == stock.symbol }) else {
            throw TestError("Updated stock not found")
        }
        
        #expect(updatedStock.price == oldPrice + 10, "Price should update from message")
        #expect(updatedStock.previousPrice == oldPrice, "Previous price should preserve old value")
        
        // Compare timestamps with tolerance
        let diff = abs(updatedStock.lastUpdated.timeIntervalSince1970 - timestamp.timeIntervalSince1970)
        #expect(diff < 0.001, "lastUpdated should match message timestamp")
    }

    @Test
    func testStartDoesNothingIfAlreadyRunning() async throws {
        setUp()
        state.start()
        let initialConnect = service.didConnect
        state.start()
        #expect(service.didConnect == initialConnect, "Repeated start should not reconnect")
    }

    @Test
    func testStopDoesNothingIfAlreadyStopped() async throws {
        setUp()
        state.stop()
        #expect(service.didDisconnect == false, "Stop on already stopped state should not disconnect")
    }
}
