//
//  StockList.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import SwiftUI

struct StockList: View {
    
    @Environment(AppState.self) private var state
    
    var body: some View {
        
        NavigationStack {
            List(state.stocks) { stock in
                NavigationLink(value: stock) {
                    StockRow(stock: stock)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    sortingMenu
                }
            }
            .navigationTitle(.stocksKey)
            .navigationDestination(for: Stock.self) { stock in
                StockDetail(stock: stock)
            }
        }
    }
}

// MARK: Components
private extension StockList {
    
    // Sorting menu
    var sortingMenu: some View {
        Menu {
            // Price
            Button {
            } label: {
                Label(.priceKey, systemImage: "dollarsign.circle")
            }
            
            // Change
            Button {
            } label: {
                Label(.changeKey, systemImage: "chart.bar.fill")
            }
            
            // Updated
            Button {
            } label: {
                Label(.updatedKey, systemImage: "clock.fill")
            }
            
        } label: {
            Label(.sortKey, systemImage: "arrow.up.arrow.down.circle")
        }
    }
}
