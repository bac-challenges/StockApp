//
//  StockRow.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import SwiftUI

struct StockRow: View {
    
    let stock: Stock

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Text(stock.symbol)
                    .font(.headline)

                Spacer()
                
                Text(String(format: "%.2f", stock.price))
            }
            
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
}

#Preview {
    StockRow(stock: Stock.sample)
}
