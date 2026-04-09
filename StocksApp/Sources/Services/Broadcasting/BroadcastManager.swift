//
//  BroadcastManager.swift
//  StocksApp
//
//  Created by emile on 08/04/2026.
//

import Foundation

@MainActor
final class BroadcastManager {
    
    private let service: PriceStreamingProtocol
    var stockLookup: (String) -> Stock?
    
    private let broadcastInterval: UInt64
    private var symbols: [String]
    private let priceGenerator: (Stock) -> Double
    
    private var symbolIndex = 0
    private var task: Task<Void, Never>?
    
    init(
        service: PriceStreamingProtocol,
        stockLookup: @escaping (String) -> Stock?,
        broadcastInterval: UInt64,
        symbols: [String],
        priceGenerator: @escaping (Stock) -> Double
    ) {
        self.service = service
        self.stockLookup = stockLookup
        self.broadcastInterval = broadcastInterval
        self.symbols = symbols
        self.priceGenerator = priceGenerator
    }
    
    func start() {
        guard task == nil else { return }
        
        task = Task { [weak self] in
            guard let self else { return }
            defer { self.task = nil }
            
            while !Task.isCancelled {
                await self.broadcastNext()
                try? await Task.sleep(nanoseconds: self.broadcastInterval)
            }
        }
    }
    
    func stop() {
        task?.cancel()
        task = nil
    }

    func updateSymbols(_ symbols: [String]) {
        self.symbols = symbols
        if symbolIndex >= symbols.count {
            symbolIndex = 0
        }
    }
    
    private func broadcastNext() async {
        guard !symbols.isEmpty else { return }
        
        let symbol = symbols[symbolIndex]
        guard let stock = stockLookup(symbol) else { return }
        
        let newPrice = priceGenerator(stock)
        let priceDelta = abs((newPrice - stock.price).rounded(toPlaces: 2))
        guard priceDelta > 0.01 else { return }
        
        let message = PriceMessage(
            symbol: symbol,
            price: newPrice,
            timestamp: Date().timeIntervalSince1970
        ).raw
        
        service.send(message)
        
        symbolIndex = (symbolIndex + 1) % symbols.count
    }
}

// MARK: Testing
extension BroadcastManager {
    func broadcastNextForTest() async {
        await broadcastNext()
    }
}
