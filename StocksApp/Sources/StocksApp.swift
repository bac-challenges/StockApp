//
//  StocksApp.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import SwiftUI

@main
struct StocksApp: App {
    
    @State private var appState = AppState(service: PriceStreamingService(),
                                           stockStore: StockStore(stocks: Stock.stocks))
    
    var body: some Scene {
        WindowGroup {
            StockList().environment(appState)
        }
    }
}
