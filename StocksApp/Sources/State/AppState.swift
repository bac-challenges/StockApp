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
    private var broadcastTask: Task<Void, Never>?
    private let broadcastInterval: UInt64
    private let symbols: [String]
    private var symbolIndex = 0
    private let priceGenerator: (Stock) -> Double
    
    /// Init
    init(service: PriceStreamingProtocol,
         broadcastInterval: UInt64 = 2_000_000_000,
         symbols: [String] = Stock.symbols,
         priceGenerator: @escaping (Stock) -> Double = { $0.price + Double.random(in: -5...5) }
    ) {
        self.service = service
        self.broadcastInterval = broadcastInterval
        self.symbols = symbols
        self.priceGenerator = priceGenerator
        self.stockStore = StockStore(stocks: Stock.stocks)
        
        bind()
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
        
        broadcastTask = Task { [weak self] in
            guard let self else { return }
            defer { self.broadcastTask = nil }
            
            while !Task.isCancelled {
                await self.broadcastNextSymbol()
                try? await Task.sleep(nanoseconds: self.broadcastInterval)
            }
        }
    }
    
    func stop() {
        lifecycle = .stopped
        broadcastTask?.cancel()
        broadcastTask = nil
        service.disconnect()
    }
}

// MARK: - Binding
private extension AppState {
    
    func bind() {
        service.messages
            .sink { [weak self] text in self?.handleMessage(text) }
            .store(in: &cancellables)

        service.connectionState
            .sink { [weak self] state in self?.connectionState = state }
            .store(in: &cancellables)
    }
}

// MARK: - Broadcasting
private extension AppState {
    
    func broadcastNextSymbol() async {
        guard lifecycle == .running, !symbols.isEmpty else { return }
        
        let symbol = symbols[symbolIndex]
        guard let stock = stockStore.stock(for: symbol) else { return }
        
        let newPrice = priceGenerator(stock)
        guard abs(newPrice - stock.price) > 0.01 else { return }
        
        let message = PriceMessage(
            symbol: symbol,
            price: newPrice,
            timestamp: Date().timeIntervalSince1970
        ).raw
        
        service.send(message)
        
        symbolIndex = (symbolIndex + 1) % symbols.count
    }
}

// MARK: - Message Handling
private extension AppState {
    
    func handleMessage(_ text: String) {
        guard let update = PriceMessage.parse(text) else { return }
        stockStore.update(update)
    }
}
