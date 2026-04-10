//
//  StockTests.swift
//  StocksAppTests
//
//  Created by Codex on 09/04/2026.
//

import Foundation
import Testing
@testable import StocksApp

@MainActor
final class StockTests {
    @Test
    func testIdMatchesSymbol() async throws {
        let stock = StockFixtures.stock(symbol: "TSLA")

        #expect(stock.id == "TSLA")
    }

    @Test
    func testChangeRoundsToTwoDecimalPlaces() async throws {
        let stock = StockFixtures.stock(price: 101.005, previousPrice: 100)

        #expect(stock.change == 1.01)
    }

    @Test
    func testChangeSupportsNegativeValues() async throws {
        let stock = StockFixtures.stock(price: 95.123, previousPrice: 100)

        #expect(stock.change == -4.88)
    }

    @Test
    func testIsUpIsTrueWhenPriceIsFlat() async throws {
        let stock = StockFixtures.stock(price: 100, previousPrice: 100)

        #expect(stock.isUp)
    }

    @Test
    func testIsUpIsFalseWhenPriceDropped() async throws {
        let stock = StockFixtures.stock(price: 90, previousPrice: 100)

        #expect(!stock.isUp)
    }
}
