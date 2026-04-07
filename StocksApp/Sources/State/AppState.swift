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
    
    /// State
    private(set) var connectionState: ConnectionState = .disconnected
    
    private(set) var lifecycle: Lifecycle = .stopped
    var isRunning: Bool { lifecycle == .running }
    
    /// Delegate stocks to store
    let stockStore: StockStore
    var stocks: [Stock] { stockStore.stocks }
    
    /// Dependencies
    private let service: PriceStreamingProtocol
    
    /// Internal
    private var cancellables = Set<AnyCancellable>()
    
    /// Init
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
        service.connect()
    }
    
    func stop() {
        lifecycle = .stopped
        service.disconnect()
    }
}

// MARK: - Binding
private extension AppState {
    
    func bind() {
        service.connectionState
            .sink { [weak self] state in self?.connectionState = state }
            .store(in: &cancellables)
    }
}

