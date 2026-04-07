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
    
    var sortType: StockSortKey = .price {
        didSet { sort() }
    }

    init(stocks: [Stock]) {
        self.stocks = stocks
        sort()
    }
}

// MARK: - Sorting
private extension StockStore {
    
    func sort() {
        stocks.sort(by: comparator())
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

// MARK: - Sorting
enum StockSortKey {
    case price, change, updated
}
