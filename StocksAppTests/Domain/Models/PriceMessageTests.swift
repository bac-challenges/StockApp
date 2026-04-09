//
//  PriceMessageTests.swift
//  StocksAppTests
//
//  Created by emile on 08/04/2026.
//

import Testing
import Foundation
@testable import StocksApp

@MainActor
final class PriceMessageTests {

    func makeMessage() -> PriceMessage {
        PriceMessage(
            symbol: "AAPL",
            price: 150.25,
            timestamp: 1234567890
        )
    }

    // MARK: - Raw Encoding
    @Test
    func testRawFormat() async throws {
        let message = makeMessage()
        
        let raw = message.raw
        
        #expect(raw == "AAPL|150.25|1234567890.0", "Raw format should match expected structure")
    }

    // MARK: - Parsing Success
    @Test
    func testParseValidMessage() async throws {
        let text = "AAPL|150.25|1234567890"
        
        let result = PriceMessage.parse(text)
        
        #expect(result != nil, "Parsing should succeed for valid input")
        #expect(result?.symbol == "AAPL")
        #expect(result?.price == 150.25)
        #expect(result?.timestamp == 1234567890)
    }

    // MARK: - Parsing Failures
    @Test
    func testParseFailsWithMissingParts() async throws {
        let text = "AAPL|150.25"
        
        let result = PriceMessage.parse(text)
        
        #expect(result == nil, "Parsing should fail if parts are missing")
    }

    @Test
    func testParseFailsWithInvalidPrice() async throws {
        let text = "AAPL|invalid|1234567890"
        
        let result = PriceMessage.parse(text)
        
        #expect(result == nil, "Parsing should fail for invalid price")
    }

    @Test
    func testParseFailsWithInvalidTimestamp() async throws {
        let text = "AAPL|150.25|invalid"
        
        let result = PriceMessage.parse(text)
        
        #expect(result == nil, "Parsing should fail for invalid timestamp")
    }

    @Test
    func testParseFailsWithEmptyString() async throws {
        let result = PriceMessage.parse("")
        
        #expect(result == nil, "Parsing should fail for empty string")
    }

    // MARK: - Edge Cases

    @Test
    func testParseHandlesNegativeValues() async throws {
        let text = "AAPL|-150.25|-1234567890"
        
        let result = PriceMessage.parse(text)
        
        #expect(result != nil, "Parsing should support negative values")
        #expect(result?.price == -150.25)
        #expect(result?.timestamp == -1234567890)
    }

    @Test
    func testParseHandlesHighPrecision() async throws {
        let text = "AAPL|150.123456789|1234567890"
        
        let result = PriceMessage.parse(text)
        
        #expect(result != nil)
        #expect(result?.price == 150.123456789)
    }

    // MARK: - Round Trip

    @Test
    func testRoundTrip() async throws {
        let original = PriceMessage(
            symbol: "TSLA",
            price: 999.99,
            timestamp: Date().timeIntervalSince1970
        )
        
        let raw = original.raw
        let parsed = PriceMessage.parse(raw)
        
        #expect(parsed != nil, "Round-trip parsing should succeed")
        #expect(parsed?.symbol == original.symbol)
        #expect(parsed?.price == original.price)
        #expect(parsed?.timestamp == original.timestamp)
    }
}
