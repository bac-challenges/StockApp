//
//  PriceStreamingService.swift
//  StocksApp
//
//  Created by Codex on 09/04/2026.
//

import Combine
import Foundation

@MainActor
final class PriceStreamingService: PriceStreamingProtocol {
    private let url = URL(string: "wss://ws.postman-echo.com/raw")!

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?

    let messageSubject = PassthroughSubject<String, Never>()
    private let stateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)

    private var shouldReconnect = false

    var messages: AnyPublisher<String, Never> {
        messageSubject.eraseToAnyPublisher()
    }

    var connectionState: AnyPublisher<ConnectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    func connect() {
        guard webSocketTask == nil else { return }

        shouldReconnect = true
        session = URLSession(configuration: .default)
        webSocketTask = session!.webSocketTask(with: url)
        webSocketTask?.resume()

        receive()

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 100_000_000)
            self?.stateSubject.send(.connected)
        }
    }

    func disconnect() {
        shouldReconnect = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        session = nil

        stateSubject.send(.disconnected)
    }

    func send(_ text: String) {
        webSocketTask?.send(.string(text)) { error in
            if let error {
                print("Send error:", error)
            }
        }
    }

    private func receive() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }

                switch result {
                case .success(let message):
                    if case let .string(text) = message {
                        self.messageSubject.send(text)
                    }
                    self.receive()

                case .failure:
                    self.stateSubject.send(.disconnected)
                    self.webSocketTask = nil

                    guard self.shouldReconnect else { return }

                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    self.connect()
                }
            }
        }
    }
}
