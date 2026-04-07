//
//  StockStore.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import Foundation

@MainActor
@Observable
final class StockStore {
    
    private(set) var stocks: [Stock] = Stock.stocks
    
    /// Sorting
    var debounceDuration: UInt64 = 200_000_000
    var sortTask: Task<Void, Never>?
    var sortType: StockSortKey = .price {
        didSet { scheduleSort() }
    }
    private var stockIndexBySymbol: [String: Int] = [:]

    init(stocks: [Stock]) {
        self.stocks = stocks
        rebuildIndex()
        scheduleSort()
    }
}

// MARK: - Public API
extension StockStore {
    
    /// Lookup stock by symbol
    func stock(for symbol: String) -> Stock? {
        guard let index = stockIndexBySymbol[symbol] else { return nil }
        return stocks[index]
    }
    
    /// Update stock
    func update(_ update: PriceMessage) {
        guard let index = stockIndexBySymbol[update.symbol] else { return }
        
        let old = stocks[index]
        
        let new = Stock(
            symbol: old.symbol,
            description: old.description,
            price: update.price,
            previousPrice: old.price,
            lastUpdated: Date(timeIntervalSince1970: update.timestamp)
        )
        
        stocks[index] = new
        scheduleSort()
    }
}

// MARK: - Sorting
enum StockSortKey {
    case price, change, updated
}

private extension StockStore {
    
    func scheduleSort() {
        sortTask?.cancel()
        
        sortTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: self?.debounceDuration ?? 0)
            self?.sort()
        }
    }
    
    func sort() {
        let oldOrder = stocks.map(\.symbol)
        
        stocks.sort(by: comparator())
        
        let newOrder = stocks.map(\.symbol)
        if oldOrder != newOrder {
            rebuildIndex()
        }
    }
    
    func comparator() -> (Stock, Stock) -> Bool {
        switch sortType {

        case .price:
            return {
                if $0.price != $1.price {
                    return $0.price > $1.price // highest first
                } else {
                    return $0.symbol < $1.symbol // tie breaker
                }
            }
            
        case .change:
            return {
                let lhsAbs = abs($0.change)
                let rhsAbs = abs($1.change)
                if lhsAbs != rhsAbs {
                    return lhsAbs > rhsAbs
                } else {
                    return $0.symbol < $1.symbol
                }
            }
            
        case .updated:
            return {
                if $0.lastUpdated != $1.lastUpdated {
                    return $0.lastUpdated > $1.lastUpdated // newest first
                } else {
                    return $0.symbol < $1.symbol
                }
            }
        }
    }
}

// MARK: - Indexing
private extension StockStore {
    func rebuildIndex() {
        stockIndexBySymbol = Dictionary(
            uniqueKeysWithValues: stocks.enumerated().map { ($1.symbol, $0) }
        )
    }
}
