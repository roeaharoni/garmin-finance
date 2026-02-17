using Toybox.Lang;
using Toybox.Communications;
using Toybox.System;

class YahooFinanceProvider {
    private var _callback as Lang.Method?;

    function initialize() {
        _callback = null;
    }

    function fetchQuote(symbol as Lang.String, callback as Lang.Method) as Void {
        _callback = callback;
        var url = "https://query1.finance.yahoo.com/v8/finance/chart/" + symbol;

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "User-Agent" => "Mozilla/5.0"
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, method(:onQuoteReceived));
    }

    function onQuoteReceived(responseCode as Lang.Number, data as Lang.Dictionary?) as Void {
        if (responseCode == 200 && data != null) {
            var parsedData = parseQuoteResponse(data as Lang.Dictionary);
            if (_callback != null) {
                _callback.invoke(parsedData);
            }
        } else {
            System.println("Yahoo Finance API error: " + responseCode);
            if (_callback != null) {
                _callback.invoke(null);
            }
        }
    }

    private function parseQuoteResponse(data as Lang.Dictionary) as Lang.Dictionary? {
        try {
            var chart = data.get("chart");
            if (chart == null) { return null; }

            var result = (chart as Lang.Dictionary).get("result");
            if (result == null || (result as Lang.Array).size() == 0) { return null; }

            var quote = (result as Lang.Array)[0];
            var meta = (quote as Lang.Dictionary).get("meta");
            if (meta == null) { return null; }

            var metaDict = meta as Lang.Dictionary;
            var regularMarketPrice = metaDict.get("regularMarketPrice");
            var previousClose = metaDict.get("previousClose");

            if (regularMarketPrice == null || previousClose == null) {
                return null;
            }

            var price = (regularMarketPrice as Lang.Float);
            var prev = (previousClose as Lang.Float);
            var change = price - prev;
            var changePercent = (change / prev) * 100;

            return {
                "value" => price,
                "change" => change,
                "changePercent" => changePercent,
                "timestamp" => System.getTimer()
            };
        } catch (ex) {
            System.println("Error parsing Yahoo Finance response");
            return null;
        }
    }

    function fetchHistory(symbol as Lang.String, callback as Lang.Method) as Void {
        callback.invoke([] as Lang.Array);
    }

    function requiresApiKey() as Lang.Boolean {
        return false;
    }

    function getApiKeyInstructions() as Lang.String {
        return "No API key required for Yahoo Finance";
    }

    function getName() as Lang.String {
        return "Yahoo Finance";
    }

    function getAlias() as Lang.String {
        return "yahoo";
    }
}
