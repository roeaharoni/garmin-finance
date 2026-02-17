using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application;

class FinanceTrackerView extends WatchUi.View {

    private var _symbols as Lang.Array<FinanceSymbol>?;
    private var _loading as Lang.Boolean = true;
    private var _errorMessage as Lang.String?;
    private var _fetchIndex as Lang.Number = 0;
    private var _fetcher as DataFetcher?;

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
        var y = 15;

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
        var itemHeight = 45;
        for (var i = 0; i < symbols.size() && i < 4; i++) {
            var symbol = symbols[i] as FinanceSymbol;
            drawFinanceSymbolItem(dc, symbol, y, width, itemHeight);
            y += itemHeight;
        }
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
                var color = chg > 0 ? Graphics.COLOR_GREEN : Graphics.COLOR_RED;
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.drawText(width - 15, valueY, Graphics.FONT_TINY, changeStr, Graphics.TEXT_JUSTIFY_RIGHT);
            }
        } else if (symbol.hasError()) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftMargin, valueY, Graphics.FONT_TINY, "Error", Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftMargin, valueY, Graphics.FONT_TINY, "Fetching...", Graphics.TEXT_JUSTIFY_LEFT);
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
        } else {
            symbol.setError(true);
            System.println("Fetch failed for " + symbol.getName());
        }

        _fetchIndex++;
        WatchUi.requestUpdate();
        fetchNextQuote();
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
