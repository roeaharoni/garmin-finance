using Toybox.Background;
using Toybox.System;
using Toybox.Application;
using Toybox.Lang;

(:background)
class BackgroundService extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        System.println("Background fetch started");

        var symbolsStr = Application.Properties.getValue("symbols");
        if (symbolsStr == null || (symbolsStr as Lang.String).equals("")) {
            Background.exit(null);
            return;
        }

        var symbols = parseSymbols(symbolsStr as Lang.String);

        var fetcher = new DataFetcher();
        if (symbols.size() > 0) {
            fetcher.fetchSymbol(symbols[0] as Lang.String, method(:onFetchComplete));
        } else {
            Background.exit(null);
        }
    }

    function onFetchComplete(success as Lang.Boolean) as Void {
        System.println("Background fetch completed");
        Background.exit(null);
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
