//
//  StockList.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import SwiftUI

struct StockListView: View {
    
    @Environment(AppStore.self) private var store
    
    var body: some View {
        
        NavigationStack {
            Group {
                if store.isBootstrapping && store.stocks.isEmpty {
                    ProgressView("Loading Stocks...")
                } else {
                    List(store.stocks) { item in
                        NavigationLink(value: item.symbol) {
                            StockRowView(stock: item)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    sortingMenu
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.startStopButtonTapped)
                    } label: {
                        connectionControl
                    }
                }
            }
            .navigationTitle(.stocksKey)
            .navigationDestination(for: String.self) { symbol in
                StockDetailView(symbol: symbol)
            }
        }
    }
}

// MARK: Components
private extension StockListView {
    
    // Sorting menu
    var sortingMenu: some View {
        Menu {
            Button {
                store.send(.sortSelected(.price))
            } label: {
                Label(.priceKey, systemImage: "dollarsign.circle")
            }
            
            Button {
                store.send(.sortSelected(.change))
            } label: {
                Label(.changeKey, systemImage: "chart.bar.fill")
            }
            
            Button {
                store.send(.sortSelected(.updated))
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
                .fill(store.connectionState == .connected ? .green : .red)
                .frame(width: 10, height: 10)
            Text("\(store.isRunning ? .stopKey : .startKey)")
        }
    }
}
