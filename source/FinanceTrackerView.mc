using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application;
using Toybox.Time;
using Toybox.Time.Gregorian;

class FinanceTrackerView extends WatchUi.View {

    private var _symbols as Lang.Array<FinanceSymbol>?;
    private var _loading as Lang.Boolean = true;
    private var _errorMessage as Lang.String?;
    private var _fetchIndex as Lang.Number = 0;
    private var _fetcher as DataFetcher?;
    private var _selectedIndex as Lang.Number = 0;
    private var _lastSyncTime as Lang.Number? = null;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onShow() as Void {
        loadData();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var y = 10;

        if (_loading) {
            dc.drawText(centerX, height / 2, Graphics.FONT_SMALL, "Loading...", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        if (_errorMessage != null) {
            dc.drawText(centerX, height / 2, Graphics.FONT_TINY, _errorMessage as Lang.String, Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        if (_symbols == null || (_symbols as Lang.Array<FinanceSymbol>).size() == 0) {
            dc.drawText(centerX, height / 2, Graphics.FONT_SMALL, "No symbols", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        var symbols = _symbols as Lang.Array<FinanceSymbol>;
        var itemHeight = 42;
        for (var i = 0; i < symbols.size() && i < 4; i++) {
            var symbol = symbols[i] as FinanceSymbol;

            // Draw selection highlight
            if (i == _selectedIndex) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
                dc.fillRectangle(0, y, width, itemHeight);
            }

            drawFinanceSymbolItem(dc, symbol, y, width, itemHeight);
            y += itemHeight;
        }

        // Draw source + last sync at bottom
        drawSourceInfo(dc, width, height);
    }

    private function drawFinanceSymbolItem(dc as Graphics.Dc, symbol as FinanceSymbol, y as Lang.Number, width as Lang.Number, height as Lang.Number) as Void {
        var leftMargin = 15;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftMargin, y, Graphics.FONT_SMALL, symbol.getName(), Graphics.TEXT_JUSTIFY_LEFT);

        var valueY = y + 22;
        if (symbol.getValue() != null) {
            var val = symbol.getValue() as Lang.Float;
            var valueStr = val.format("%.2f");
            dc.drawText(leftMargin, valueY, Graphics.FONT_TINY, valueStr, Graphics.TEXT_JUSTIFY_LEFT);

            var change = symbol.getChange();
            if (change != null && (change as Lang.Float) != 0) {
                var chg = change as Lang.Float;
                var changeStr = (chg > 0 ? "+" : "") + chg.format("%.2f");

                // Append percentage if available
                var pct = symbol.getChangePercent();
                if (pct != null) {
                    var pctVal = pct as Lang.Float;
                    changeStr += " (" + (pctVal > 0 ? "+" : "") + pctVal.format("%.1f") + "%)";
                }

                var color = chg > 0 ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width - 15, valueY, Graphics.FONT_XTINY, changeStr, Graphics.TEXT_JUSTIFY_RIGHT);
            }
        } else if (symbol.hasError()) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftMargin, valueY, Graphics.FONT_TINY, "Error", Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftMargin, valueY, Graphics.FONT_TINY, "Fetching...", Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    private function drawSourceInfo(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        var infoStr = "";
        if (_fetcher != null) {
            infoStr = (_fetcher as DataFetcher).getProviderName();
        }

        if (_lastSyncTime != null) {
            var syncMoment = new Time.Moment(_lastSyncTime as Lang.Number);
            var info = Gregorian.info(syncMoment, Time.FORMAT_SHORT);
            var hourNum = info.hour as Lang.Number;
            var minNum = info.min as Lang.Number;
            var timeStr = hourNum.format("%02d") + ":" + minNum.format("%02d");
            infoStr += " " + timeStr;
        }

        if (!infoStr.equals("")) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height - 22, Graphics.FONT_XTINY, infoStr, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function loadData() as Void {
        _loading = true;

        var symbolsStr = "USD/EUR,BTC/USD,SPY";
        try {
            var app = Application.getApp();
            var symVal = app.getProperty("symbols");
            if (symVal != null && symVal instanceof Lang.String && (symVal as Lang.String).length() > 0) {
                symbolsStr = symVal as Lang.String;
            }
        } catch (ex) {
            System.println("Properties access failed, using defaults");
        }

        var symbolNames = parseFinanceSymbols(symbolsStr);
        _symbols = [] as Lang.Array<FinanceSymbol>;

        for (var i = 0; i < symbolNames.size(); i++) {
            var name = symbolNames[i] as Lang.String;
            var sym = new FinanceSymbol(name);
            (_symbols as Lang.Array<FinanceSymbol>).add(sym);
        }

        _loading = false;
        _selectedIndex = 0;

        // Create fetcher (uses ProviderFactory to select provider)
        _fetcher = new DataFetcher();
        System.println("Using provider: " + (_fetcher as DataFetcher).getProviderAlias());

        // Start fetching quotes sequentially
        _fetchIndex = 0;
        fetchNextQuote();
    }

    private function fetchNextQuote() as Void {
        if (_symbols == null || _fetcher == null) { return; }
        var symbols = _symbols as Lang.Array<FinanceSymbol>;
        if (_fetchIndex >= symbols.size()) { return; }

        var symbol = symbols[_fetchIndex] as FinanceSymbol;
        (_fetcher as DataFetcher).fetchSymbol(symbol.getName(), method(:onQuoteReceived));
    }

    function onQuoteReceived(data as Lang.Dictionary?) as Void {
        if (_symbols == null) { return; }
        var symbols = _symbols as Lang.Array<FinanceSymbol>;
        if (_fetchIndex >= symbols.size()) { return; }

        var symbol = symbols[_fetchIndex] as FinanceSymbol;

        if (data != null) {
            var d = data as Lang.Dictionary;
            symbol.setValue(d.get("value") as Lang.Float?);
            symbol.setChange(d.get("change") as Lang.Float?);
            symbol.setChangePercent(d.get("changePercent") as Lang.Float?);

            // OHLC data
            symbol.setOpen(d.get("open") as Lang.Float?);
            symbol.setHigh(d.get("high") as Lang.Float?);
            symbol.setLow(d.get("low") as Lang.Float?);
            symbol.setPreviousClose(d.get("previousClose") as Lang.Float?);

            // 52-week data
            symbol.setFiftyTwoWeekHigh(d.get("fiftyTwoWeekHigh") as Lang.Float?);
            symbol.setFiftyTwoWeekLow(d.get("fiftyTwoWeekLow") as Lang.Float?);

            // Track sync time
            _lastSyncTime = Time.now().value();
            symbol.setLastUpdated(_lastSyncTime);
        } else {
            symbol.setError(true);
            System.println("Fetch failed for " + symbol.getName());
        }

        _fetchIndex++;
        WatchUi.requestUpdate();
        fetchNextQuote();
    }

    function getSelectedSymbol() as FinanceSymbol? {
        if (_symbols == null) { return null; }
        var symbols = _symbols as Lang.Array<FinanceSymbol>;
        if (_selectedIndex >= 0 && _selectedIndex < symbols.size()) {
            return symbols[_selectedIndex] as FinanceSymbol;
        }
        return null;
    }

    function getFetcher() as DataFetcher? {
        return _fetcher;
    }

    function moveSelectionUp() as Void {
        if (_symbols == null) { return; }
        if (_selectedIndex > 0) {
            _selectedIndex--;
        }
    }

    function moveSelectionDown() as Void {
        if (_symbols == null) { return; }
        var symbols = _symbols as Lang.Array<FinanceSymbol>;
        var maxIndex = symbols.size() - 1;
        if (maxIndex > 3) { maxIndex = 3; }
        if (_selectedIndex < maxIndex) {
            _selectedIndex++;
        }
    }

    private function parseFinanceSymbols(str as Lang.String) as Lang.Array {
        var result = [] as Lang.Array;
        var current = "";

        for (var i = 0; i < str.length(); i++) {
            var ch = str.substring(i, i + 1);
            if (ch.equals(",")) {
                var trimmed = trimStr(current);
                if (trimmed.length() > 0) {
                    result.add(trimmed);
                }
                current = "";
            } else {
                current += ch;
            }
        }

        var trimmed = trimStr(current);
        if (trimmed.length() > 0) {
            result.add(trimmed);
        }

        return result;
    }

    private function trimStr(str as Lang.String) as Lang.String {
        var start = 0;
        var end = str.length();

        while (start < end && str.substring(start, start + 1).equals(" ")) {
            start++;
        }

        while (end > start && str.substring(end - 1, end).equals(" ")) {
            end--;
        }

        return start < end ? str.substring(start, end) as Lang.String : "";
    }
}
