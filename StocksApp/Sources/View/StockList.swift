//
//  StockList.swift
//  StocksApp
//
//  Created by emile on 07/04/2026.
//

import SwiftUI

struct StockList: View {
    
    private let items: [Stock] = [
        Stock.sample,
        Stock.sample,
        Stock.sample
    ]
    
    var body: some View {
        List(items) { item in
            Text(item.symbol)
        }
    }
}

#Preview {
    StockList()
}
