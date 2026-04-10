//
//  PriceStreamingProtocol.swift
//  StocksApp
//
//  Created by Codex on 09/04/2026.
//

import Combine

@MainActor
protocol PriceStreamingProtocol {
    var messages: AnyPublisher<String, Never> { get }
    var connectionState: AnyPublisher<ConnectionState, Never> { get }

    func connect()
    func disconnect()
    func send(_ text: String)
}
