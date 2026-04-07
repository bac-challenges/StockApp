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
    }
}

// MARK: - Sorting
private extension StockStore {
    
    func sort() {
        print(sortType)
    }
}

// MARK: - Sorting
enum StockSortKey {
    case price, change, updated
}
