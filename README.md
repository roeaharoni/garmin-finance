# Garmin Finance Tracker

A Garmin Connect IQ application for tracking currencies, stocks, and crypto prices on your Garmin watch.

## Features

- Real-time financial quotes displayed on your watch
- Up to 4 symbols tracked simultaneously (currencies, stocks, crypto)
- Change indicators (green/red) showing price movement
- Multiple data providers: Twelve Data (default), Alpha Vantage, Yahoo Finance
- Offline caching via persistent storage
- Configurable via Garmin Connect Mobile app or simulator settings
- Glance widget for quick price overview

## Data Providers

The app supports three data providers, selectable in settings:

| Provider | API Key | Free Tier | Best For |
|----------|---------|-----------|----------|
| **Twelve Data** (default) | Required | 800 calls/day, 8/min | Best all-around free option |
| **Alpha Vantage** | Required | 25 calls/day | Backup option, very limited |
| **Yahoo Finance** | Not required | Unlimited (unofficial) | Quick testing without API key |

### Getting API Keys

- **Twelve Data**: Free at https://twelvedata.com — sign up and copy your API key
- **Alpha Vantage**: Free at https://www.alphavantage.co/support/#api-key

Yahoo Finance requires no API key but may be unreliable as it uses an unofficial endpoint.

### Adding a New Provider

The app uses a pluggable provider architecture. See [ARCHITECTURE.md](ARCHITECTURE.md#implementing-a-new-provider) for a step-by-step guide on implementing and registering new providers.

## Supported Devices

- Fenix 7 Series (7S, 7, 7X, Pro, Solar)
- Fenix 6 Series
- Vivoactive 3 & 4 Series
- Forerunner 245, 255, 265, 645, 745, 955, 965
- Venu, Venu 2, Venu 3, Venu Sq Series

## Building the App

### Prerequisites

- Java (installed)
- Garmin Connect IQ SDK 8.4.1+
- Visual Studio Code with Monkey C extension (optional)

### Build via Command Line

```bash
monkeyc -d fenix7spro -f monkey.jungle -o bin/FinanceTracker.prg -y <developer_key>
```

### Build in VS Code

1. Open the project in VS Code
2. Press `Cmd+Shift+P` (or `Ctrl+Shift+P` on Windows/Linux)
3. Type "Monkey C: Build for Device" and select it
4. Choose your target device

### Run in Simulator

```bash
monkeydo bin/FinanceTracker.prg fenix7spro
```

Or press `F5` in VS Code and select "Run with Simulator".

## Configuration

### Settings

| Setting | Options | Default | Description |
|---------|---------|---------|-------------|
| **Data Provider** | Twelve Data, Alpha Vantage, Yahoo Finance | Twelve Data | Which API to fetch prices from |
| **API Key** | *(text)* | *(empty)* | API key for Twelve Data or Alpha Vantage |
| **Symbols** | *(text)* | `USD/EUR,BTC/USD,SPY` | Comma-separated list of symbols |
| **Refresh Interval** | 5min, 15min, 30min, 1hr | 15 minutes | How often to refresh prices |

### How to Change Settings

**On device** (via Garmin Connect Mobile):
1. Open Garmin Connect Mobile
2. Go to Device Settings > Apps > Finance Tracker > Settings

**In simulator**:
1. File > Edit Application > Settings

**For development/testing** — edit `resources/properties/properties.xml` directly:
```xml
<properties>
    <property id="dataProvider" type="number">0</property>
    <property id="apiKey" type="string">your-api-key-here</property>
    <property id="symbols" type="string">USD/EUR,BTC/USD,SPY</property>
    <property id="refreshInterval" type="number">1</property>
</properties>
```

## Symbol Format

| Type | Format | Examples |
|------|--------|---------|
| Currency pairs | `XXX/YYY` | `USD/EUR`, `GBP/USD`, `JPY/EUR` |
| Crypto | `XXX/USD` | `BTC/USD`, `ETH/USD` |
| Stocks/ETFs | Ticker | `AAPL`, `GOOGL`, `SPY`, `TSLA` |

## Project Structure

```
garmin-finance/
├── source/
│   ├── FinanceTrackerApp.mc       # App entry point
│   ├── FinanceTrackerView.mc      # Main list view + fetch orchestration
│   ├── FinanceTrackerDelegate.mc  # Input handler
│   ├── FinanceWidget.mc           # Glance widget
│   ├── DetailView.mc              # Single symbol detail view
│   ├── DetailDelegate.mc          # Detail view input handler
│   ├── data/
│   │   ├── DataFetcher.mc         # Fetch coordinator (bridges view ↔ provider)
│   │   ├── DataCache.mc           # Persistent storage cache
│   │   ├── ProviderFactory.mc     # Maps settings to provider instances
│   │   ├── models/
│   │   │   ├── Symbol.mc          # FinanceSymbol (name, value, change, error)
│   │   │   ├── Currency.mc        # Currency pair model
│   │   │   ├── Stock.mc           # Stock model
│   │   │   └── DataPoint.mc       # Historical data point
│   │   └── providers/
│   │       ├── IDataProvider.mc        # Provider interface (base class)
│   │       ├── TwelveDataProvider.mc   # Twelve Data API
│   │       ├── AlphaVantageProvider.mc # Alpha Vantage API
│   │       └── YahooFinanceProvider.mc # Yahoo Finance API
│   ├── ui/                        # UI components
│   ├── background/                # Background service
│   └── utils/                     # Utilities
├── resources/
│   ├── properties/                # Default property values
│   ├── settings/                  # Garmin Connect settings UI
│   ├── strings/                   # Localization
│   ├── drawables/                 # Icons and images
│   └── layouts/                   # UI layouts
├── manifest.xml                   # App manifest
├── monkey.jungle                  # Build configuration
└── ARCHITECTURE.md                # Detailed architecture docs
```

## Architecture

The app follows a layered architecture:

```
FinanceTrackerView  →  DataFetcher  →  ProviderFactory  →  Provider (API call)
       ↑                    ↓
   UI rendering         DataCache (persistent storage)
```

- **View** reads symbols from settings, creates `DataFetcher`, fetches quotes sequentially
- **DataFetcher** delegates to the configured provider and caches results
- **ProviderFactory** reads the `dataProvider` setting and instantiates the right provider
- **Providers** handle API-specific logic and return normalized `{ value, change, changePercent }` data

See [ARCHITECTURE.md](ARCHITECTURE.md) for full details including the provider interface, networking model, and implementation guide.

## Troubleshooting

- **"Fetching..." stays forever** — Check phone connection and internet. Verify API key is set if using Twelve Data or Alpha Vantage.
- **"Error" in red** — The provider returned an error. Check the console log for details.
- **No data after provider switch** — Make sure to set the API key if the new provider requires one.
- **Build errors about properties** — Ensure `resources/properties` is in `resourcePath` in `monkey.jungle`.

## License

This project is provided as-is for educational and personal use.

## Credits

Built for Garmin Connect IQ SDK 8.4.1
Target Device: Fenix 7S Pro
