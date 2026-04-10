//
//  StockRow.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import SwiftUI

struct StockRowView: View {
    
    let stock: Stock
    
    @State
    private var flashColor: Color? = nil

    var body: some View {
        VStack(alignment: .leading) {
            stockInfo
            stockDetails
        }
        .onChange(of: stock.price) {
            if stock.price != stock.previousPrice {
                flashColor = stock.isUp ? .green : .red
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    flashColor = nil
                }
            }
        }
    }
}

// MARK: Components
private extension StockRowView {
    
    /// Stock Info
    var stockInfo: some View {
        HStack(alignment: .top) {
            Text(stock.symbol)
                .font(.headline)
                .foregroundColor(flashColor ?? .primary)
                .animation(.easeInOut(duration: 0.2), value: flashColor)

            Spacer()
            
            Text(String(format: "%.2f", stock.price))
                .foregroundColor(flashColor ?? .primary)
                .animation(.easeInOut(duration: 0.2), value: flashColor)
        }
    }
    
    /// Stock Details
    var stockDetails: some View {
        HStack(alignment: .bottom, spacing: 2) {
            
            Spacer()
            
            Text(String(format: "%.2f", stock.change))
                .foregroundColor(stock.isUp ? .green : .red)
                .font(.caption)
            
            Text(stock.isUp ? "↑" : "↓")
                .foregroundColor(stock.isUp ? .green : .red)
                .font(.caption)
        }
    }
}
