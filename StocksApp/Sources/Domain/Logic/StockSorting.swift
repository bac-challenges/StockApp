//
//  StockSorting.swift
//  StocksApp
//
//  Created by Codex on 09/04/2026.
//

import Foundation

enum StockSorting {
    static func updatedStocks(_ stocks: [Stock], with update: PriceMessage) -> [Stock] {
        stocks.map { stock in
            guard stock.symbol == update.symbol else { return stock }

            return Stock(
                symbol: stock.symbol,
                description: stock.description,
                price: update.price,
                previousPrice: stock.price,
                lastUpdated: Date(timeIntervalSince1970: update.timestamp)
            )
        }
    }

    static func sortedStocks(_ stocks: [Stock], by sortType: StockSortKey) -> [Stock] {
        stocks.sorted(by: comparator(for: sortType))
    }

    private static func comparator(for sortType: StockSortKey) -> (Stock, Stock) -> Bool {
        switch sortType {
        case .price:
            return {
                if $0.price != $1.price {
                    return $0.price > $1.price
                }
                return $0.symbol < $1.symbol
            }

        case .change:
            return {
                let lhsAbs = abs($0.change)
                let rhsAbs = abs($1.change)
                if lhsAbs != rhsAbs {
                    return lhsAbs > rhsAbs
                }
                return $0.symbol < $1.symbol
            }

        case .updated:
            return {
                if $0.lastUpdated != $1.lastUpdated {
                    return $0.lastUpdated > $1.lastUpdated
                }
                return $0.symbol < $1.symbol
            }
        }
    }
}
