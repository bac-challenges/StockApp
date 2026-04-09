//
//  AppStore.swift
//  StocksApp
//
//  Created by Codex on 09/04/2026.
//

import Combine
import Observation
import SwiftUI

@MainActor
@Observable
final class AppStore {
    private(set) var state: StocksFeature.State
    private(set) var isBootstrapping = false

    @ObservationIgnored
    private let service: PriceStreamingProtocol
    @ObservationIgnored
    private let stockFetchingService: StockFetchingProtocol
    @ObservationIgnored
    private let broadcaster: BroadcastManager
    @ObservationIgnored
    private let sortDebounceDuration: UInt64

    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored
    private var sortTask: Task<Void, Never>?
    @ObservationIgnored
    private var hasBootstrapped = false

    init(
        priceBroadcastService: PriceStreamingProtocol,
        stockFetchingService: StockFetchingProtocol,
        initialStocks: [Stock] = [],
        broadcastInterval: UInt64 = 2_000_000_000,
        sortDebounceDuration: UInt64 = 200_000_000,
        priceGenerator: @escaping (Stock) -> Double = { $0.price + Double.random(in: -5...5) }
    ) {
        self.service = priceBroadcastService
        self.stockFetchingService = stockFetchingService
        self.sortDebounceDuration = sortDebounceDuration
        self.state = StocksFeature.State(
            stocks: StockSorting.sortedStocks(initialStocks, by: .price)
        )
        self.broadcaster = BroadcastManager(
            service: priceBroadcastService,
            stockLookup: { _ in nil },
            broadcastInterval: broadcastInterval,
            symbols: Self.uniqueSymbols(from: initialStocks),
            priceGenerator: priceGenerator
        )

        self.broadcaster.stockLookup = { [weak self] symbol in
            self?.state.stock(for: symbol)
        }

        bind()
    }

    var stocks: [Stock] {
        state.stocks
    }

    var isRunning: Bool {
        state.isRunning
    }

    var connectionState: ConnectionState {
        state.connectionState
    }

    func stock(for symbol: String) -> Stock? {
        state.stock(for: symbol)
    }

    func send(_ action: StocksFeature.Action) {
        let commands = StocksFeature.reduce(state: &state, action: action)
        handle(commands)
    }

    func bootstrap() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true
        isBootstrapping = true
        defer { isBootstrapping = false }

        do {
            let stocks = try await stockFetchingService.fetchStocks()
            state.stocks = StockSorting.sortedStocks(stocks, by: state.sortType)
            broadcaster.updateSymbols(uniqueSymbols(from: stocks))
            send(.start)
        } catch {
            hasBootstrapped = false
        }
    }
}

@MainActor
private extension AppStore {
    static func uniqueSymbols(from stocks: [Stock]) -> [String] {
        var seen = Set<String>()
        return stocks.compactMap { stock in
            guard seen.insert(stock.symbol).inserted else { return nil }
            return stock.symbol
        }
    }

    func bind() {
        service.messages
            .sink { [weak self] text in
                self?.send(.receivedMessage(text))
            }
            .store(in: &cancellables)

        service.connectionState
            .sink { [weak self] connectionState in
                self?.send(.connectionStateChanged(connectionState))
            }
            .store(in: &cancellables)
    }

    func handle(_ commands: [StocksFeature.Command]) {
        for command in commands {
            switch command {
            case .connect:
                service.connect()

            case .disconnect:
                service.disconnect()

            case .startBroadcasting:
                broadcaster.start()

            case .stopBroadcasting:
                broadcaster.stop()

            case .scheduleSort:
                scheduleSort()
            }
        }
    }

    func scheduleSort() {
        sortTask?.cancel()
        sortTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: sortDebounceDuration)
            guard !Task.isCancelled else { return }
            send(.sortDebounceElapsed)
        }
    }

    func uniqueSymbols(from stocks: [Stock]) -> [String] {
        Self.uniqueSymbols(from: stocks)
    }
}
