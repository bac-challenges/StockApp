//
//  MockStreamingServiceTests.swift
//  StocksAppTests
//
//  Created by Codex on 09/04/2026.
//

import Combine
import Foundation
import Testing
@testable import StocksApp

@MainActor
final class MockStreamingServiceTests {
    @Test
    func testConnectPublishesConnectedState() async throws {
        let service = MockStreamingService()
        var receivedStates: [ConnectionState] = []
        let cancellable = service.connectionState.sink { receivedStates.append($0) }
        defer { cancellable.cancel() }

        service.connect()

        #expect(service.didConnect)
        #expect(receivedStates.last == .connected)
    }

    @Test
    func testDisconnectPublishesDisconnectedState() async throws {
        let service = MockStreamingService()
        var receivedStates: [ConnectionState] = []
        let cancellable = service.connectionState.sink { receivedStates.append($0) }
        defer { cancellable.cancel() }

        service.disconnect()

        #expect(service.didDisconnect)
        #expect(receivedStates.last == .disconnected)
    }

    @Test
    func testSendCapturesAndPublishesMessage() async throws {
        let service = MockStreamingService()
        var receivedMessages: [String] = []
        let cancellable = service.messages.sink { receivedMessages.append($0) }
        defer { cancellable.cancel() }

        service.send("AAPL|150|123")

        #expect(service.sentMessages == ["AAPL|150|123"])
        #expect(receivedMessages == ["AAPL|150|123"])
    }
}
