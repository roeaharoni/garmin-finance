using Toybox.Lang;
using Toybox.Communications;
using Toybox.System;
using Toybox.Application;

class AlphaVantageProvider {
    private var _callback as Lang.Method?;

    function initialize() {
        _callback = null;
    }

    function fetchQuote(symbol as Lang.String, callback as Lang.Method) as Void {
        _callback = callback;
        var apiKey = "";
        try {
            var keyVal = Application.getApp().getProperty("apiKey");
            if (keyVal != null && keyVal instanceof Lang.String) {
                apiKey = keyVal as Lang.String;
            }
        } catch (ex) {
            System.println("Could not read API key");
        }
        if (apiKey.equals("")) {
            System.println("Alpha Vantage requires API key");
            callback.invoke(null);
            return;
        }

        var url = "https://www.alphavantage.co/query";
        var params = {
            "function" => "GLOBAL_QUOTE",
            "symbol" => symbol,
            "apikey" => apiKey
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, params, options, method(:onQuoteReceived));
    }

    function onQuoteReceived(responseCode as Lang.Number, data as Lang.Dictionary?) as Void {
        if (responseCode == 200 && data != null) {
            var parsedData = parseQuoteResponse(data as Lang.Dictionary);
            if (_callback != null) {
                _callback.invoke(parsedData);
            }
        } else {
            if (_callback != null) {
                _callback.invoke(null);
            }
        }
    }

    private function parseQuoteResponse(data as Lang.Dictionary) as Lang.Dictionary? {
        try {
            var globalQuote = data.get("Global Quote");
            if (globalQuote == null) { return null; }

            var gq = globalQuote as Lang.Dictionary;
            var price = gq.get("05. price");
            var change = gq.get("09. change");
            var changePercent = gq.get("10. change percent");

            if (price == null) { return null; }

            return {
                "value" => (price as Lang.String).toFloat(),
                "change" => change != null ? (change as Lang.String).toFloat() : 0.0,
                "changePercent" => changePercent != null ? parsePercent(changePercent as Lang.String) : 0.0,
                "timestamp" => System.getTimer()
            };
        } catch (ex) {
            return null;
        }
    }

    private function parsePercent(str as Lang.String) as Lang.Float {
        var cleaned = str.substring(0, str.length() - 1);
        return (cleaned as Lang.String).toFloat();
    }

    function fetchHistory(symbol as Lang.String, callback as Lang.Method) as Void {
        callback.invoke([] as Lang.Array);
    }

    function requiresApiKey() as Lang.Boolean {
        return true;
    }

    function getApiKeyInstructions() as Lang.String {
        return "Get free API key from alphavantage.co";
    }

    function getName() as Lang.String {
        return "Alpha Vantage";
    }

    function getAlias() as Lang.String {
        return "alphavantage";
    }
}
