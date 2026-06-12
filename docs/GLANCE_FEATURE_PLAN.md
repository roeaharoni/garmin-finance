# Plan: Add a Glance (widget) view with background refresh

## Context

The Finance Tracker currently runs **only as a full app** launched from the app menu. During initial planning a glance/widget was requested but never wired up. The goal is for the app to also appear in the watch's **glance list** (the dashboard you scroll to from the watch face) showing a small summary — symbol, price, and change — where tapping it opens the full app.

Good news from exploration: a `WatchUi.GlanceView` subclass (`FinanceWidget`) **already exists and is correctly written** — it just was never connected to the app. The remaining work is wiring + two chosen enhancements:
- **Background refresh** so the glance shows fresh-ish data even without opening the app.
- **% change** shown in each glance row (instead of just a +/- arrow).

Key facts verified against the SDK 8.4.1 docs/schema (target `fenix7spro`, which supports glances):
- A glance is enabled **purely by overriding `AppBase.getGlanceView()`** — **no manifest or `monkey.jungle` change** is needed (there is no `<iq:glance>` element in the manifest schema).
- **Tapping a glance opens the full app automatically** — built-in OS behavior, nothing to implement.
- The glance reads cached prices from `Application.Storage` via `DataCache` (persists across launches).
- Background services in Connect IQ are a **separate compiled scope**: only code annotated `(:background)` is compiled into it. Adding `getServiceDelegate()` will make the compiler build that scope and **require `(:background)` on every class reachable from `BackgroundService`** — this is the main implementation work.

## Changes

### 1. `source/FinanceTrackerApp.mc` — wire up glance, service delegate, and temporal registration
Add module imports `Toybox.Background`, `Toybox.System`, `Toybox.Time` (alongside existing `Application`, `Lang`, `WatchUi`). Add these methods (all type annotations fully module-qualified per project convention):

- `getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null` → `return [new FinanceWidget()];`
- `getServiceDelegate() as [System.ServiceDelegate]` → `return [new BackgroundService()];`
- `onBackgroundData(data as Application.PersistableType) as Void` → `WatchUi.requestUpdate();` (not load-bearing — the glance reads Storage directly — just nudges a refresh).
- A private `registerTemporalEvent()` helper called from `onStart()`:
  - Read `refreshInterval` via `Application.Properties.getValue` wrapped in **try/catch** (default 15 min), map `0→5, 1→15, 2→30, 3→60` minutes (all ≥ the 5-min CIQ minimum, so always valid), build `new Time.Duration(minutes * 60)`.
  - Only register when needed to avoid resetting the schedule every launch: register if `Background.getTemporalEventRegisteredTime() == null`, **or** if the interval changed since last registration (store the registered minutes in `Storage` under e.g. `"registeredInterval"` and compare). `registerForTemporalEvent` overwrites any existing event, so re-registering on change is safe.

### 2. `source/background/BackgroundService.mc` — refresh up to 3 symbols, fix async/exit flow
The current `onTemporalEvent` only fetches `symbols[0]` (so glance rows 2–3 never populate) and `onFetchComplete(success as Lang.Boolean)` has the **wrong signature** — `DataFetcher`'s callback passes a `Lang.Dictionary?` (the quote) / `null`, not a Boolean. Rework to:
- Wrap `Properties.getValue("symbols")` in try/catch; `Background.exit(null)` on empty/missing.
- Parse symbols, **cap to 3** (`slice(0,3)`) to match the glance and stay within the ~30s background budget.
- **Sequential, index-chained** fetch: store `_symbols`/`_index`/`_fetcher` as members; `fetchNext()` fetches `_symbols[_index]` via `fetcher.fetchSymbol(name, method(:onFetchComplete))`; `onFetchComplete(data)` increments `_index` and calls `fetchNext()`; when `_index >= size`, call `Background.exit(null)`.
- **Invariant:** call `Background.exit` *only* from the terminal callback — never synchronously at the end of `onTemporalEvent` — so no `makeWebRequest` is outstanding when the service exits (avoids the classic premature-exit race). The web write to `Storage` happens inside `DataFetcher.onDataReceived` before our callback runs, so each symbol is persisted before the next starts.
- Fix `onFetchComplete` parameter to `data` (Dictionary/null), not Boolean.

### 3. Add `(:background)` annotations to the background reachability graph
Once `getServiceDelegate()` exists, the compiler builds the background scope and will fail the type check on any reachable symbol lacking `(:background)`. Annotate these classes (reachable from `BackgroundService` → `DataFetcher` → `ProviderFactory` → providers → `DataCache`):
- `source/data/DataFetcher.mc`, `source/data/ProviderFactory.mc`, `source/data/DataCache.mc`
- `source/data/providers/IDataProvider.mc`, `TwelveDataProvider.mc`, `AlphaVantageProvider.mc`, `YahooFinanceProvider.mc` (factory can instantiate any of the three)
- `source/data/models/DataPoint.mc` (referenced inside `DataCache.storeHistory`)
- `source/utils/HttpUtil.mc`, `source/utils/JsonParser.mc` (used by providers)

Apply `(:background)` at the class level for a clean first pass. **Resolve any remaining "referencing non-background symbol" build errors by adding `(:background)` to whatever the compiler flags** — the build is the source of truth here. (No `excludeAnnotations` is added to `monkey.jungle`, so non-background scopes are unaffected. The glance scope needs **no** annotations — `FinanceWidget`+`DataCache` are tiny and well under the 32KB glance budget.)

### 4. `source/FinanceWidget.mc` — show % change instead of bare arrow
In `drawSymbol`, read `changePercent` from the cache (already stored by `DataCache.store`) and render e.g. `+1.5%` / `-0.8%` in green/red (right-justified), replacing the bare `+`/`-` arrow. Handle `null`/missing `changePercent` gracefully (fall back to nothing or `--`). Pass `changePercent` through from `onUpdate` (it already pulls `value` and `change` from the cached dict).

## Verification

1. Build for the watch:
   ```
   "/Users/roei/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.1-2026-02-03-e9f77eeaa/bin/monkeyc" \
     -d fenix7spro -f monkey.jungle -o bin/FinanceTracker.prg \
     -y "/Users/roei/Library/Application Support/Garmin/ConnectIQ/developer_key"
   ```
   Iterate on any `(:background)` type-check errors until `BUILD SUCCESSFUL`.
2. **Simulator** (`connectiq` simulator + `monkeydo bin/FinanceTracker.prg fenix7spro`): confirm the app appears in the **glance list**, the glance renders symbol/price/%‑change, and selecting it launches the full app. Use the simulator's background-event trigger to fire `onTemporalEvent` and confirm the cache updates and the glance shows numbers.
3. **On-device** (sideload the rebuilt `.prg` to `GARMIN/APPS/` via OpenMTP, as done previously): add the app's glance to the glance loop, confirm it shows data after the app is opened once, and that it refreshes on its own per the `refreshInterval` setting. Live data requires the phone paired via Garmin Connect Mobile and a valid API key for the selected provider.

## Notes / risks
- Background refresh only updates the symbols shown in the glance (first 3). The full app still fetches all configured symbols on open.
- On lower-memory devices the glance uses "background UI update" (cached render, `requestUpdate()` is a no-op); `fenix7spro` is music-capable so it gets live updates — both paths work with this design.
- No new files; no manifest/jungle/strings changes required (the `GlanceName` string already exists if needed later).
