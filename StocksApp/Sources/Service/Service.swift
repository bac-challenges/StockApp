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
    
    private let messageSubject = PassthroughSubject<String, Never>()
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.stateSubject.send(.connected)
        }
    }
    
    func disconnect() {
        
    }
    
    func send(_ text: String) {

    }
}
