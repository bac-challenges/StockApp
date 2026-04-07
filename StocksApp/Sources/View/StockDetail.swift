//
//  StockDetail.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import SwiftUI

struct SymbolDetail: View {
    
    let stock: Stock
    
    var body: some View {
        VStack(spacing: 5) {
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
        .padding()
        .navigationTitle(stock.symbol)
        .navigationBarTitleDisplayMode(.inline)
    }
}
