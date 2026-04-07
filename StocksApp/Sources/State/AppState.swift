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
    
    let stockStore: StockStore
    var stocks: [Stock] { stockStore.stocks }
    let isRunning = false
    
    init() {
        self.stockStore = StockStore(stocks: Stock.stocks)
    }

    func start() {}
    func stop() {}
}
