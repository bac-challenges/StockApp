//
//  Service.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import Foundation
import Combine

enum ConnectionState {
    case connected
    case disconnected
}

protocol PriceStreamingProtocol {
    
    var messages: AnyPublisher<String, Never> { get }
    var connectionState: AnyPublisher<ConnectionState, Never> { get }
    
    func connect()
    func disconnect()
    func send(_ text: String)
}

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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.stateSubject.send(.connected)
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
            guard let self = self else { return }

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
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                    self.connect()
                }
            }
        }
    }
}

// MARK: Mock Service
#if DEBUG
final class MockStreamingService: PriceStreamingProtocol {
    
    var sentMessages: [String] = []

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
        sentMessages.append(text)
        _messages.send(text)
    }
}
#endif
