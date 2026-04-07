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

protocol PriceServiceProtocol {
    
    var messages: AnyPublisher<String, Never> { get }
    var connectionState: AnyPublisher<ConnectionState, Never> { get }
    
    func connect()
    func disconnect()
    func send(_ text: String)
}
