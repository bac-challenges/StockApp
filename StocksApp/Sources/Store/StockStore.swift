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

    init(stocks: [Stock]) {
        self.stocks = stocks
    }
}
