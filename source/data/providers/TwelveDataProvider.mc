using Toybox.Lang;
using Toybox.Communications;
using Toybox.System;
using Toybox.Application;

class TwelveDataProvider {
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
            System.println("Twelve Data requires API key");
            callback.invoke(null);
            return;
        }

        var url = "https://api.twelvedata.com/quote?symbol=" + symbol + "&apikey=" + apiKey;

        System.println("TwelveData fetching: " + symbol);

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
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
            System.println("Twelve Data API error: " + responseCode);
            if (_callback != null) {
                _callback.invoke(null);
            }
        }
    }

    private function parseQuoteResponse(data as Lang.Dictionary) as Lang.Dictionary? {
        try {
            var closeVal = data.get("close");
            if (closeVal == null) { return null; }

            var price = toFloat(closeVal);
            if (price == null) { return null; }

            var change = 0.0f;
            var changeVal = data.get("change");
            if (changeVal != null) {
                var chg = toFloat(changeVal);
                if (chg != null) {
                    change = chg as Lang.Float;
                }
            }

            var changePercent = 0.0f;
            var pctVal = data.get("percent_change");
            if (pctVal != null) {
                var pct = toFloat(pctVal);
                if (pct != null) {
                    changePercent = pct as Lang.Float;
                }
            }

            return {
                "value" => price as Lang.Float,
                "change" => change,
                "changePercent" => changePercent,
                "timestamp" => System.getTimer()
            };
        } catch (ex) {
            System.println("Error parsing Twelve Data response");
            return null;
        }
    }

    private function toFloat(val) as Lang.Float? {
        if (val instanceof Lang.Float) {
            return val as Lang.Float;
        }
        if (val instanceof Lang.Number) {
            return (val as Lang.Number).toFloat();
        }
        if (val instanceof Lang.String) {
            return (val as Lang.String).toFloat();
        }
        return null;
    }

    function fetchHistory(symbol as Lang.String, callback as Lang.Method) as Void {
        callback.invoke([] as Lang.Array);
    }

    function requiresApiKey() as Lang.Boolean {
        return true;
    }

    function getApiKeyInstructions() as Lang.String {
        return "Get free API key from twelvedata.com";
    }

    function getName() as Lang.String {
        return "Twelve Data";
    }

    function getAlias() as Lang.String {
        return "twelvedata";
    }
}
