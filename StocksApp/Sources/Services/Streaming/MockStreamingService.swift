//
//  MockStreamingService.swift
//  StocksApp
//
//  Created by Codex on 09/04/2026.
//

#if DEBUG
import Combine

@MainActor
final class MockStreamingService: PriceStreamingProtocol {
    var sentMessages: [String] = []

    private let messagesSubject = PassthroughSubject<String, Never>()
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)

    var messages: AnyPublisher<String, Never> { messagesSubject.eraseToAnyPublisher() }
    var connectionState: AnyPublisher<ConnectionState, Never> { connectionStateSubject.eraseToAnyPublisher() }

    private(set) var didConnect = false
    private(set) var didDisconnect = false

    func connect() {
        didConnect = true
        connectionStateSubject.send(.connected)
    }

    func disconnect() {
        didDisconnect = true
        connectionStateSubject.send(.disconnected)
    }

    func send(_ text: String) {
        sentMessages.append(text)
        messagesSubject.send(text)
    }
}
#endif
