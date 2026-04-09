//
//  StockFetchingProtocol.swift
//  StocksApp
//
//  Created by Codex on 09/04/2026.
//

@MainActor
protocol StockFetchingProtocol {
    func fetchStocks() async throws -> [Stock]
}
