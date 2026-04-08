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
    
    /// Store
    let stockStore: StockStore
    var stocks: [Stock] { stockStore.stocks }
    
    /// Dependencies
    private let service: PriceStreamingProtocol
    private let broadcaster: BroadcastManager
    
    /// Internal
    private var cancellables = Set<AnyCancellable>()
    
    /// Init
    init(
        service: PriceStreamingProtocol,
        broadcastInterval: UInt64 = 2_000_000_000,
        symbols: [String] = Stock.symbols,
        priceGenerator: @escaping (Stock) -> Double = { $0.price + Double.random(in: -5...5) }
    ) {
        self.service = service
        self.stockStore = StockStore(stocks: Stock.stocks)
        
        self.broadcaster = BroadcastManager(
            service: service,
            stockStore: stockStore,
            broadcastInterval: broadcastInterval,
            symbols: symbols,
            priceGenerator: priceGenerator
        )
        
        bind()
    }
}

extension AppState {
    
    enum Lifecycle {
        case stopped
        case running
    }
    
    func start() {
        guard lifecycle == .stopped else { return }
        
        lifecycle = .running
        service.connect()
        broadcaster.start()
    }
    
    func stop() {
        lifecycle = .stopped
        broadcaster.stop()
        service.disconnect()
    }
}

@MainActor
private extension AppState {
    
    func bind() {
        service.messages
            .sink { [weak self] text in
                self?.handleMessage(text)
            }
            .store(in: &cancellables)

        service.connectionState
            .sink { [weak self] state in
                self?.connectionState = state
            }
            .store(in: &cancellables)
    }
}

@MainActor
private extension AppState {
    
    func handleMessage(_ text: String) {
        guard let update = PriceMessage.parse(text) else { return }
        stockStore.update(update)
    }
}
