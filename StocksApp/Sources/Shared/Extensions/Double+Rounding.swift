//
//  Double+Rounding.swift
//  StocksApp
//
//  Created by Codex on 09/04/2026.
//

import Foundation

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let precision = max(places + 8, 16)
        let normalized = String(format: "%.\(precision)f", self)

        var decimal = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")) ?? Decimal(self)
        var roundedDecimal = Decimal()

        NSDecimalRound(&roundedDecimal, &decimal, places, .plain)
        return NSDecimalNumber(decimal: roundedDecimal).doubleValue
    }
}
