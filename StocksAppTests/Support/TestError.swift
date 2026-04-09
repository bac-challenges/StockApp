//
//  TestError.swift
//  StocksAppTests
//
//  Created by Codex on 09/04/2026.
//

import Foundation

struct TestError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
