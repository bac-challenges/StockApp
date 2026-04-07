//
//  StockList.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import SwiftUI

struct StockList: View {
    
    private let stocks: [Stock] = Stock.stocks
    
    var body: some View {
        
        NavigationStack {
            List(stocks) { stock in
                NavigationLink(value: stock) {
                    StockRow(stock: stock)
                }
            }
            .navigationTitle(.stocksKey)
            .navigationDestination(for: Stock.self) { stock in
                StockDetail(stock: stock)
            }
        }
    }
}

#Preview {
    StockList()
}
