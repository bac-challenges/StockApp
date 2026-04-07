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
}

#if DEBUG
final class MockPriceStreamingService: PriceStreamingProtocol {
    
    private let messageSubject = PassthroughSubject<String, Never>()
    private let stateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    
    private var timer: Timer?
    
    var messages: AnyPublisher<String, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    var connectionState: AnyPublisher<ConnectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    func connect() {
        guard stateSubject.value == .disconnected else { return }
        stateSubject.send(.connected)
    }
    
    func disconnect() {
        stateSubject.send(.disconnected)
    }
}
#endif
