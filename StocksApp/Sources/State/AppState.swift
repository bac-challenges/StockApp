//
//  AppState.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import SwiftUI
import Combine

@MainActor
protocol AppStateProtocol: Observable {
    var stocks: [Stock] { get }
    var isRunning: Bool { get }

    func start()
    func stop()
}

@MainActor
@Observable
final class AppState: AppStateProtocol {
    
    private(set) var connectionState: ConnectionState = .disconnected
    private(set) var lifecycle: Lifecycle = .stopped
    let isRunning = false
    
    let stockStore: StockStore
    var stocks: [Stock] { stockStore.stocks }
    
    private let service: PriceStreamingProtocol
    
    init(service: PriceStreamingProtocol) {
        self.service = service
        self.stockStore = StockStore(stocks: Stock.stocks)
    }
}

// MARK: - Lifecycle
extension AppState {

    enum Lifecycle {
        case stopped
        case running
    }
    
    func start() {
        guard lifecycle == .stopped else { return }
        lifecycle = .running
    }
    
    func stop() {
        lifecycle = .stopped
    }
}
