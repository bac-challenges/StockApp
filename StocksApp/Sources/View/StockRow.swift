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
        Text(stock.symbol)
    }
}

#Preview {
    StockRow(stock: Stock.sample)
}
