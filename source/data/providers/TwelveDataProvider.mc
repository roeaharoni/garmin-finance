using Toybox.Lang;
using Toybox.Communications;
using Toybox.System;
using Toybox.Application;

class TwelveDataProvider {
    private var _callback as Lang.Method?;
    private var _historyCallback as Lang.Method?;

    function initialize() {
        _callback = null;
        _historyCallback = null;
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

            var result = {
                "value" => price as Lang.Float,
                "change" => change,
                "changePercent" => changePercent,
                "timestamp" => System.getTimer()
            } as Lang.Dictionary;

            // Extract OHLC data
            var openVal = data.get("open");
            if (openVal != null) {
                var o = toFloat(openVal);
                if (o != null) { result.put("open", o); }
            }

            var highVal = data.get("high");
            if (highVal != null) {
                var h = toFloat(highVal);
                if (h != null) { result.put("high", h); }
            }

            var lowVal = data.get("low");
            if (lowVal != null) {
                var l = toFloat(lowVal);
                if (l != null) { result.put("low", l); }
            }

            var prevCloseVal = data.get("previous_close");
            if (prevCloseVal != null) {
                var pc = toFloat(prevCloseVal);
                if (pc != null) { result.put("previousClose", pc); }
            }

            // Extract 52-week data (nested dict)
            var ftw = data.get("fifty_two_week");
            if (ftw != null && ftw instanceof Lang.Dictionary) {
                var ftwDict = ftw as Lang.Dictionary;
                var ftwHigh = ftwDict.get("high");
                if (ftwHigh != null) {
                    var fh = toFloat(ftwHigh);
                    if (fh != null) { result.put("fiftyTwoWeekHigh", fh); }
                }
                var ftwLow = ftwDict.get("low");
                if (ftwLow != null) {
                    var fl = toFloat(ftwLow);
                    if (fl != null) { result.put("fiftyTwoWeekLow", fl); }
                }
            }

            return result;
        } catch (ex) {
            System.println("Error parsing Twelve Data response");
            return null;
        }
    }

    function fetchHistory(symbol as Lang.String, range as Lang.String, callback as Lang.Method) as Void {
        _historyCallback = callback;

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
            callback.invoke([] as Lang.Array);
            return;
        }

        var interval = "1day";
        var outputsize = "30";
        if (range.equals("yearly")) {
            interval = "1week";
            outputsize = "52";
        }

        var url = "https://api.twelvedata.com/time_series?symbol=" + symbol +
            "&interval=" + interval + "&outputsize=" + outputsize + "&apikey=" + apiKey;

        System.println("TwelveData fetching history: " + symbol + " (" + range + ")");

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, method(:onHistoryReceived));
    }

    function onHistoryReceived(responseCode as Lang.Number, data as Lang.Dictionary?) as Void {
        if (responseCode == 200 && data != null) {
            var points = parseHistoryResponse(data as Lang.Dictionary);
            if (_historyCallback != null) {
                _historyCallback.invoke(points);
            }
        } else {
            System.println("Twelve Data history error: " + responseCode);
            if (_historyCallback != null) {
                _historyCallback.invoke([] as Lang.Array);
            }
        }
    }

    private function parseHistoryResponse(data as Lang.Dictionary) as Lang.Array {
        var result = [] as Lang.Array;
        try {
            var values = data.get("values");
            if (values == null || !(values instanceof Lang.Array)) {
                return result;
            }

            var valuesArr = values as Lang.Array;
            // Values come newest-first, reverse for chronological order
            for (var i = valuesArr.size() - 1; i >= 0; i--) {
                var item = valuesArr[i] as Lang.Dictionary;
                var closeVal = item.get("close");
                if (closeVal != null) {
                    var val = toFloat(closeVal);
                    if (val != null) {
                        result.add(new DataPoint(i, val as Lang.Float));
                    }
                }
            }
        } catch (ex) {
            System.println("Error parsing Twelve Data history");
        }
        return result;
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
