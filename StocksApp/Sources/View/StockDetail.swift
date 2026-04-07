//
//  StockDetail.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import SwiftUI

struct StockDetail: View {
    
    @Environment(AppState.self) private var state
    
    let symbol: String
    
    var stock: Stock? {
        state.stockStore.stock(for: symbol)
    }
    
    var body: some View {
        VStack(spacing: 5) {
            if let stock {
                Text(stock.symbol).font(.largeTitle)
                    
                Text(String(format: "%.2f", stock.price)).font(.title)
                    
                HStack(alignment: .bottom, spacing: 2) {
                    Text(stock.isUp ? "↑" : "↓")
                        .foregroundColor(stock.isUp ? .green : .red)
                        
                    Text(String(format: "%.2f", stock.change))
                        .foregroundColor(stock.isUp ? .green : .red)
                }
                    
                Text(stock.description).foregroundColor(.secondary)
            }
        }
        .padding()
        .navigationTitle(symbol)
        .navigationBarTitleDisplayMode(.inline)
    }
}
