//
//  StockListFeature.swift
//  StocksApp
//
//  Created by Codex on 09/04/2026.
//

enum StocksFeature {
    enum Lifecycle {
        case stopped
        case running
    }

    struct State {
        var connectionState: ConnectionState = .disconnected
        var lifecycle: Lifecycle = .stopped
        var stocks: [Stock]
        var sortType: StockSortKey = .price

        var isRunning: Bool {
            lifecycle == .running
        }

        func stock(for symbol: String) -> Stock? {
            stocks.first { $0.symbol == symbol }
        }
    }

    enum Action {
        case startStopButtonTapped
        case start
        case stop
        case sortSelected(StockSortKey)
        case receivedMessage(String)
        case connectionStateChanged(ConnectionState)
        case sortDebounceElapsed
    }

    enum Command {
        case connect
        case disconnect
        case startBroadcasting
        case stopBroadcasting
        case scheduleSort
    }

    static func reduce(state: inout State, action: Action) -> [Command] {
        switch action {
        case .startStopButtonTapped:
            return reduce(state: &state, action: state.isRunning ? .stop : .start)

        case .start:
            guard state.lifecycle == .stopped else { return [] }
            state.lifecycle = .running
            return [.connect, .startBroadcasting]

        case .stop:
            guard state.lifecycle == .running else { return [] }
            state.lifecycle = .stopped
            return [.stopBroadcasting, .disconnect]

        case let .sortSelected(sortType):
            state.sortType = sortType
            return [.scheduleSort]

        case let .receivedMessage(text):
            guard let update = PriceMessage.parse(text) else { return [] }
            state.stocks = StockSorting.updatedStocks(state.stocks, with: update)
            return [.scheduleSort]

        case let .connectionStateChanged(connectionState):
            state.connectionState = connectionState
            return []

        case .sortDebounceElapsed:
            state.stocks = StockSorting.sortedStocks(state.stocks, by: state.sortType)
            return []
        }
    }
}
