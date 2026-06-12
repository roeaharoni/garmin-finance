using Toybox.Background;
using Toybox.System;
using Toybox.Application;
using Toybox.Lang;

(:background)
class BackgroundService extends System.ServiceDelegate {

    private var _symbols as Lang.Array;
    private var _index as Lang.Number;
    private var _fetcher as DataFetcher?;

    function initialize() {
        ServiceDelegate.initialize();
        _symbols = [] as Lang.Array;
        _index = 0;
        _fetcher = null;
    }

    function onTemporalEvent() as Void {
        System.println("Background fetch started");

        var symbolsStr = null;
        try {
            symbolsStr = Application.Properties.getValue("symbols");
        } catch (ex) {
            Background.exit(null);
            return;
        }

        if (symbolsStr == null || (symbolsStr as Lang.String).equals("")) {
            Background.exit(null);
            return;
        }

        _symbols = parseSymbols(symbolsStr as Lang.String);
        // The glance only shows the first 3 symbols, so refreshing more would
        // waste the ~30s background budget.
        if (_symbols.size() > 3) {
            _symbols = _symbols.slice(0, 3);
        }

        if (_symbols.size() == 0) {
            Background.exit(null);
            return;
        }

        _index = 0;
        _fetcher = new DataFetcher();
        fetchNext();
    }

    // Fetches symbols one at a time. Each request's completion callback advances
    // to the next, so only one web request is ever outstanding and Background.exit
    // is reached strictly after the last symbol has been written to Storage.
    private function fetchNext() as Void {
        if (_index >= _symbols.size()) {
            System.println("Background fetch completed");
            Background.exit(null);
            return;
        }

        var sym = _symbols[_index] as Lang.String;
        (_fetcher as DataFetcher).fetchSymbol(sym, method(:onFetchComplete));
    }

    // DataFetcher invokes this with the parsed quote Dictionary (or null on
    // failure) AFTER it has already persisted the result to Storage.
    function onFetchComplete(data as Lang.Dictionary?) as Void {
        _index++;
        fetchNext();
    }

    private function parseSymbols(str as Lang.String) as Lang.Array {
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
