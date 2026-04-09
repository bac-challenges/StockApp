//
//  StocksApp.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import SwiftUI

@main
struct StocksApp: App {
    
    @State private var store = AppStore(
        priceBroadcastService: PriceStreamingService(),
        stockFetchingService: MockFetchingService()
    )
    
    var body: some Scene {
        WindowGroup {
            StockListView()
                .environment(store)
                .task {
                    await store.bootstrap()
                }
        }
    }
}
