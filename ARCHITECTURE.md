# Garmin Finance Tracker - Architecture

## Overview

A Garmin Connect IQ watch app that displays real-time financial quotes (stocks, currencies, crypto) on compatible Garmin watches. The app supports multiple data providers, displays prices with nominal and percentage change indicators, and provides a detail view with OHLC data and historical price charts.

## How It Works

### Networking Model

**The watch never makes HTTP requests directly.** All network requests are proxied through the paired phone:

```
Watch App                    Phone                       Internet
(Monkey C)               (Garmin Connect               (Data Provider
                          Mobile App)                    API)

  Communications          Bluetooth                     HTTPS
  .makeWebRequest() ───────────────> Garmin Connect ──────────> api.twelvedata.com
                                     Mobile App                 (or alphavantage.co,
                                                                yahoo finance, etc.)
        <────────────────────────────────────────────────────────
        onQuoteReceived()            Response forwarded
                                     back via Bluetooth
```

1. The watch app calls `Communications.makeWebRequest()` with a URL, parameters, and a callback method.
2. The Connect IQ runtime serializes this request and sends it to the **Garmin Connect Mobile** app on the paired phone via Bluetooth.
3. The phone app makes the actual HTTPS request to the internet (data provider API).
4. The response is sent back to the watch over Bluetooth.
5. The watch app's callback method (`onQuoteReceived`) is invoked with the response code and parsed data.

This design is **mandatory in Connect IQ** — there is no way for the watch to make direct HTTP requests.

### Requirements
- The watch must be paired with a phone running Garmin Connect Mobile
- The phone must have an active internet connection
- If the phone is out of Bluetooth range, requests will fail (responseCode != 200)

## App Structure

```
source/
├── FinanceTrackerApp.mc        # App entry point
├── FinanceTrackerView.mc       # Main view: symbol list, selection cursor, source/sync info
├── FinanceTrackerDelegate.mc   # Input handler: UP/DOWN selection, SELECT → detail view
├── FinanceWidget.mc            # Glance widget (watch face widget view)
├── DetailView.mc               # Detail view: OHLC, 52-week, line chart, daily/yearly modes
├── DetailDelegate.mc           # Detail input: UP/DOWN toggles mode, BACK returns to list
├── data/
│   ├── models/
│   │   ├── Symbol.mc           # FinanceSymbol class (name, value, change, OHLC, 52-week)
│   │   ├── Currency.mc         # Currency pair (extends FinanceSymbol)
│   │   ├── Stock.mc            # Stock (extends FinanceSymbol, has company name)
│   │   └── DataPoint.mc        # Historical data point (timestamp + value)
│   ├── DataCache.mc            # Persistent storage cache (Application.Storage)
│   ├── DataFetcher.mc          # Orchestrates fetching via selected provider
│   ├── ProviderFactory.mc      # Creates provider instance based on settings
│   └── providers/
│       ├── IDataProvider.mc        # Provider base class (interface)
│       ├── TwelveDataProvider.mc   # Twelve Data API (default)
│       ├── AlphaVantageProvider.mc # Alpha Vantage API
│       └── YahooFinanceProvider.mc # Yahoo Finance API
├── ui/
│   ├── UIHelpers.mc            # Drawing utility functions
│   ├── GraphView.mc            # Price chart rendering
│   └── SymbolListItem.mc       # List item drawable
├── utils/
│   ├── HttpUtil.mc             # HTTP request helpers
│   ├── JsonParser.mc           # JSON path extraction
│   └── DateUtil.mc             # Date formatting
└── background/
    └── BackgroundService.mc    # Background data refresh service
```

## Data Flow

### Main List
1. **App Start** → `FinanceTrackerApp.getInitialView()` creates `FinanceTrackerView` + `FinanceTrackerDelegate(view)`
2. **View Shown** → `onShow()` calls `loadData()`
3. **Load Data** → Reads symbol list from Properties (settings), falls back to defaults (`USD/EUR,BTC/USD,SPY`)
4. **Provider Selection** → `DataFetcher` uses `ProviderFactory` to instantiate the configured provider
5. **Fetch Quotes** → Sequential fetch: one symbol at a time via the selected provider
   - `DataFetcher.fetchSymbol()` → Provider's `fetchQuote()` → `Communications.makeWebRequest()` (through phone)
   - On response: provider parses API-specific JSON → returns normalized dict with price, change, OHLC, 52-week data
   - `DataFetcher` caches full result and invokes the view callback with the data dict (or `null` on failure)
   - View populates the `FinanceSymbol` with all fields and triggers `fetchNextQuote()` for the next symbol
6. **Display** → `onUpdate()` renders up to 4 symbols with price and change `+0.14 (+0.13%)` in green/red
7. **Selection** → UP/DOWN moves the selection cursor (highlighted row); SELECT opens detail view
8. **Source Info** → Provider name + last sync time shown at bottom of screen
9. **Error Handling** → Failed fetches show "Error" in red; symbols awaiting data show "Fetching..." in gray

### Detail View
1. **Entry** → SELECT on a symbol pushes `DetailView(symbol, fetcher)` + `DetailDelegate(view)`
2. **History Fetch** → `onShow()` triggers `DataFetcher.fetchHistory(symbol, range, callback)` for chart data
3. **Daily Mode** (default) — Displays OHLC (Open/High/Low/Close) + 30-day line chart
4. **Yearly Mode** — Displays 52-week High/Low + 52-week line chart
5. **Mode Toggle** → UP/DOWN switches between daily and yearly, triggers new history fetch
6. **Back** → BACK button returns to the main list via `popView()`

## Provider Architecture

### Overview

The app uses a pluggable provider system. All providers extend `IDataProvider` and return data in a normalized format, so the view layer is completely decoupled from any specific API.

```
FinanceTrackerView
        │
        ▼
   DataFetcher ──── DataCache (persistent storage)
        │
        ▼
  ProviderFactory
        │
        ├── 0 → TwelveDataProvider   (default)
        ├── 1 → AlphaVantageProvider
        └── 2 → YahooFinanceProvider
```

### IDataProvider Interface

All providers extend `IDataProvider` ([IDataProvider.mc](source/data/providers/IDataProvider.mc)):

```monkey-c
class IDataProvider {
    function fetchQuote(symbol as Lang.String, callback as Lang.Method) as Void {}
    function fetchHistory(symbol as Lang.String, range as Lang.String, callback as Lang.Method) as Void {}
    function requiresApiKey() as Lang.Boolean { return false; }
    function getApiKeyInstructions() as Lang.String { return ""; }
    function getName() as Lang.String { return "Unknown"; }
    function getAlias() as Lang.String { return "unknown"; }
}
```

| Method | Description |
|--------|-------------|
| `fetchQuote(symbol, callback)` | Fetch current price + OHLC + 52-week data. Invokes `callback` with a data `Dictionary` or `null` on failure. |
| `fetchHistory(symbol, range, callback)` | Fetch historical price data. `range` is `"daily"` (30-day, 1-day interval) or `"yearly"` (52-week, 1-week interval). Invokes `callback` with `DataPoint` array. |
| `requiresApiKey()` | Whether this provider needs an API key to function. |
| `getApiKeyInstructions()` | User-facing text on how to obtain an API key. |
| `getName()` | Human-readable provider name (e.g. `"Twelve Data"`). |
| `getAlias()` | Short identifier string (e.g. `"twelvedata"`). Used for logging and identification. |

### Normalized Response Format

All providers return data in the same dictionary format via the `fetchQuote` callback:

```monkey-c
{
    "value"              => Lang.Float,    // Current price (close)
    "change"             => Lang.Float,    // Absolute change from previous close
    "changePercent"      => Lang.Float,    // Percentage change
    "open"               => Lang.Float,    // Daily open price (optional)
    "high"               => Lang.Float,    // Daily high (optional)
    "low"                => Lang.Float,    // Daily low (optional)
    "previousClose"      => Lang.Float,    // Previous close (optional)
    "fiftyTwoWeekHigh"   => Lang.Float,    // 52-week high (optional, not available on Alpha Vantage)
    "fiftyTwoWeekLow"    => Lang.Float,    // 52-week low (optional, not available on Alpha Vantage)
    "timestamp"          => Lang.Number    // System.getTimer() at fetch time
}
```

The `fetchHistory` callback receives a `Lang.Array` of `DataPoint` objects (timestamp + value), in chronological order.

On failure, `fetchQuote` callback receives `null`; `fetchHistory` callback receives an empty array.

### Implementing a New Provider

1. Create a new file in `source/data/providers/` (e.g. `MyProvider.mc`)
2. Extend `IDataProvider` and implement all methods:
   ```monkey-c
   using Toybox.Lang;
   using Toybox.Communications;
   using Toybox.System;

   class MyProvider {
       private var _callback as Lang.Method?;
       private var _historyCallback as Lang.Method?;

       function initialize() {
           _callback = null;
           _historyCallback = null;
       }

       function fetchQuote(symbol as Lang.String, callback as Lang.Method) as Void {
           _callback = callback;
           // Build URL, make request
           Communications.makeWebRequest(url, params, options, method(:onQuoteReceived));
       }

       function onQuoteReceived(responseCode as Lang.Number, data as Lang.Dictionary?) as Void {
           if (responseCode == 200 && data != null) {
               var result = {
                   "value" => price,
                   "change" => change,
                   "changePercent" => changePercent,
                   "timestamp" => System.getTimer()
               } as Lang.Dictionary;
               // Add OHLC + 52-week data if available
               result.put("open", openPrice);
               result.put("high", highPrice);
               result.put("low", lowPrice);
               result.put("previousClose", prevClose);
               result.put("fiftyTwoWeekHigh", ftwHigh);
               result.put("fiftyTwoWeekLow", ftwLow);
               if (_callback != null) { _callback.invoke(result); }
           } else {
               if (_callback != null) { _callback.invoke(null); }
           }
       }

       function fetchHistory(symbol as Lang.String, range as Lang.String, callback as Lang.Method) as Void {
           _historyCallback = callback;
           // range is "daily" (30 points, 1-day interval) or "yearly" (52 points, 1-week interval)
           // Fetch time series data, parse into DataPoint array, invoke callback
       }

       function requiresApiKey() as Lang.Boolean { return true; }
       function getApiKeyInstructions() as Lang.String { return "Get key at..."; }
       function getName() as Lang.String { return "My Provider"; }
       function getAlias() as Lang.String { return "myprovider"; }
   }
   ```
3. Register in `ProviderFactory.mc` — add a new numeric index mapping
4. Add a `<listEntry>` in `resources/settings/settings.xml` with the next numeric value

**Important patterns:**
- Store callbacks as instance variables (`_callback` for quotes, `_historyCallback` for history) — Monkey C does not support `Method.bindWith()`
- The `onQuoteReceived` and `onHistoryReceived` methods must be **public** (referenced via `method(:...)`)
- Read API keys via `Application.getApp().getProperty("apiKey")` wrapped in try/catch
- Handle responses where values may come as `String`, `Float`, or `Number` — use a `toFloat()` helper
- Extract OHLC and 52-week data from the existing quote API response (no extra API call needed)
- History data (`fetchHistory`) requires a separate API call — use `DataPoint(timestamp, value)` for each point

### Available Providers

| Provider | Alias | API Key | Free Tier | History | Notes |
|----------|-------|---------|-----------|---------|-------|
| **Twelve Data** | `twelvedata` | Required | 800 calls/day, 8/min | Yes (`/time_series`) | Default. OHLC + 52-week from `/quote`. |
| **Alpha Vantage** | `alphavantage` | Required | 25 calls/day | No (too limited) | OHLC from `GLOBAL_QUOTE`. No 52-week data. |
| **Yahoo Finance** | `yahoo` | Not required | Unlimited (unofficial) | Yes (`/v8/finance/chart`) | OHLC + 52-week from chart meta. |

### ProviderFactory

[ProviderFactory.mc](source/data/ProviderFactory.mc) maps the numeric `dataProvider` setting to a provider instance:

| Setting Value | Provider |
|---------------|----------|
| `0` (default) | `TwelveDataProvider` |
| `1` | `AlphaVantageProvider` |
| `2` | `YahooFinanceProvider` |

The factory reads `Application.getApp().getProperty("dataProvider")` with try/catch, defaulting to `0` (Twelve Data).

### DataFetcher

[DataFetcher.mc](source/data/DataFetcher.mc) sits between the view and providers:
- Creates a provider via `ProviderFactory`
- **Quote fetching**: `fetchSymbol(symbol, callback)` — manages one pending quote request, caches full response (OHLC + 52-week), invokes callback with data dict or `null`
- **History fetching**: `fetchHistory(symbol, range, callback)` — separate pending state from quotes, caches DataPoint arrays, invokes callback with DataPoint array
- Caches all data in `DataCache` (persistent `Application.Storage`)

## Settings

Configurable via Garmin Connect Mobile or simulator (**File** > **Edit Application** > **Settings**):

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `dataProvider` | `number` | `0` | Provider: 0=Twelve Data, 1=Alpha Vantage, 2=Yahoo Finance |
| `apiKey` | `string` | *(empty)* | API key for Twelve Data or Alpha Vantage |
| `symbols` | `string` | `USD/EUR,BTC/USD,SPY` | Comma-separated symbols to track |
| `refreshInterval` | `number` | `1` | Refresh interval: 0=5min, 1=15min, 2=30min, 3=1hr |

**Note:** Connect IQ list settings require numeric values. The `dataProvider` and `refreshInterval` settings use numeric indices mapped to their respective options.

## Symbol Format

| Type | Format | Example |
|------|--------|---------|
| Currency pair | `USD/EUR` | US Dollar to Euro |
| Crypto | `BTC/USD` | Bitcoin in USD |
| Stock/ETF | `SPY` | S&P 500 ETF |

Symbol format is passed directly to the provider. Yahoo Finance internally converts symbols (e.g. `USD/EUR` → `USDEUR=X`).

## Build

```bash
monkeyc -d fenix7spro -f monkey.jungle -o bin/FinanceTracker.prg -y <developer_key>
```

Target device can be changed (e.g., `venu2`, `fr965`). See `manifest.xml` for supported devices.

## Known Gotchas

- `Application.Properties.getValue()` crashes at runtime — use `Application.getApp().getProperty()` with try/catch and defaults
- `String.split()` does not exist in Monkey C — manual character-by-character parsing required
- `Method.bindWith()` does not exist — store callbacks as instance variables
- All HTTP requests go through the paired phone via Bluetooth — no direct internet from the watch
- Connect IQ list settings require numeric `value` attributes, not strings
