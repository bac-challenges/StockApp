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
            List(state.stocks) { item in
                NavigationLink(value: item.symbol) {
                    StockRow(stock: item)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    sortingMenu
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        state.isRunning ? state.stop():state.start()
                    } label: {
                        connectionControl
                    }
                }
            }
            .navigationTitle(.stocksKey)
            .navigationDestination(for: String.self) { symbol in
                StockDetail(symbol: symbol)
            }
        }
    }
}

// MARK: Components
private extension StockList {
    
    // Sorting menu
    var sortingMenu: some View {
        Menu {
            /// Price
            Button {
                state.stockStore.sortType = .price
            } label: {
                Label(.priceKey, systemImage: "dollarsign.circle")
            }
            
            /// Change
            Button {
                state.stockStore.sortType = .change
            } label: {
                Label(.changeKey, systemImage: "chart.bar.fill")
            }
            
            /// Updated
            Button {
                state.stockStore.sortType = .updated
            } label: {
                Label(.updatedKey, systemImage: "clock.fill")
            }
            
        } label: {
            Label(.sortKey, systemImage: "arrow.up.arrow.down.circle")
        }
    }
    
    // Connection control
    var connectionControl: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(state.connectionState == .connected ? .green : .red)
                .frame(width: 10, height: 10)
            Text("\(state.isRunning ? .stopKey : .startKey)")
        }
    }
}
