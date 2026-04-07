# StocksApp

**StocksApp** is a **SwiftUI** application that simulates a real-time stock ticker. It leverages **Combine** and async/await to provide live price updates for a predefined set of stocks. The app is designed to demonstrate reactive state management and broadcasting updates without requiring a live backend connection.

## Features
- **Real-time stock updates:** Prices are broadcasted at regular intervals using a configurable price generator.
- **Sorting:** Stocks can be sorted by price, price change, or last updated time.
- **Connection simulation:** Connect or disconnect the price streaming service with a single button.
- **Navigation:** Tap a stock to view detailed information in a dedicated screen.
- **Reactive architecture:** Uses **@Observable**, **Combine**, and **Swift Concurrency** for efficient state updates.


## Architecture
- **AppState:** Central state manager conforming to AppStateProtocol. Handles lifecycle, price broadcasting, and message handling.
- **StockStore**: Manages stock data, updates, and sorting.
- **PriceStreamingService**: Simulates a WebSocket connection for broadcasting and receiving stock prices.
- **Views**:
    - **StockList**: Displays all stocks and allows sorting.
    - **StockRow**: Displays individual stock information.
    - **StockDetail**: Shows detailed view for a selected stock.
