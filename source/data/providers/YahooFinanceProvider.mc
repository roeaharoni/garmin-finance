using Toybox.Lang;
using Toybox.Communications;
using Toybox.System;

class YahooFinanceProvider {
    private var _callback as Lang.Method?;
    private var _historyCallback as Lang.Method?;

    function initialize() {
        _callback = null;
        _historyCallback = null;
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

            var resultArr = (chart as Lang.Dictionary).get("result");
            if (resultArr == null || (resultArr as Lang.Array).size() == 0) { return null; }

            var quote = (resultArr as Lang.Array)[0];
            var meta = (quote as Lang.Dictionary).get("meta");
            if (meta == null) { return null; }

            var metaDict = meta as Lang.Dictionary;
            var regularMarketPrice = metaDict.get("regularMarketPrice");
            var previousClose = metaDict.get("previousClose");

            if (regularMarketPrice == null || previousClose == null) {
                return null;
            }

            var price = toFloat(regularMarketPrice);
            var prev = toFloat(previousClose);
            if (price == null || prev == null) { return null; }

            var priceF = price as Lang.Float;
            var prevF = prev as Lang.Float;
            var change = priceF - prevF;
            var changePercent = prevF != 0.0 ? (change / prevF) * 100 : 0.0;

            var result = {
                "value" => priceF,
                "change" => change,
                "changePercent" => changePercent,
                "previousClose" => prevF,
                "timestamp" => System.getTimer()
            } as Lang.Dictionary;

            // Extract OHLC data from meta
            var openVal = metaDict.get("regularMarketDayOpen");
            if (openVal != null) {
                var o = toFloat(openVal);
                if (o != null) { result.put("open", o); }
            }

            var highVal = metaDict.get("regularMarketDayHigh");
            if (highVal != null) {
                var h = toFloat(highVal);
                if (h != null) { result.put("high", h); }
            }

            var lowVal = metaDict.get("regularMarketDayLow");
            if (lowVal != null) {
                var l = toFloat(lowVal);
                if (l != null) { result.put("low", l); }
            }

            // Extract 52-week data from meta
            var ftwHigh = metaDict.get("fiftyTwoWeekHigh");
            if (ftwHigh != null) {
                var fh = toFloat(ftwHigh);
                if (fh != null) { result.put("fiftyTwoWeekHigh", fh); }
            }

            var ftwLow = metaDict.get("fiftyTwoWeekLow");
            if (ftwLow != null) {
                var fl = toFloat(ftwLow);
                if (fl != null) { result.put("fiftyTwoWeekLow", fl); }
            }

            return result;
        } catch (ex) {
            System.println("Error parsing Yahoo Finance response");
            return null;
        }
    }

    function fetchHistory(symbol as Lang.String, range as Lang.String, callback as Lang.Method) as Void {
        _historyCallback = callback;

        var rangeParam = "1mo";
        var intervalParam = "1d";
        if (range.equals("yearly")) {
            rangeParam = "1y";
            intervalParam = "1wk";
        }

        var url = "https://query1.finance.yahoo.com/v8/finance/chart/" + symbol +
            "?range=" + rangeParam + "&interval=" + intervalParam;

        System.println("Yahoo fetching history: " + symbol + " (" + range + ")");

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "User-Agent" => "Mozilla/5.0"
            },
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
            System.println("Yahoo history error: " + responseCode);
            if (_historyCallback != null) {
                _historyCallback.invoke([] as Lang.Array);
            }
        }
    }

    private function parseHistoryResponse(data as Lang.Dictionary) as Lang.Array {
        var result = [] as Lang.Array;
        try {
            var chart = data.get("chart");
            if (chart == null) { return result; }

            var resultArr = (chart as Lang.Dictionary).get("result");
            if (resultArr == null || (resultArr as Lang.Array).size() == 0) { return result; }

            var entry = (resultArr as Lang.Array)[0] as Lang.Dictionary;
            var timestamps = entry.get("timestamp");
            var indicators = entry.get("indicators");

            if (timestamps == null || indicators == null) { return result; }

            var quoteArr = (indicators as Lang.Dictionary).get("quote");
            if (quoteArr == null || (quoteArr as Lang.Array).size() == 0) { return result; }

            var quoteData = (quoteArr as Lang.Array)[0] as Lang.Dictionary;
            var closes = quoteData.get("close");

            if (closes == null) { return result; }

            var tsArr = timestamps as Lang.Array;
            var closeArr = closes as Lang.Array;

            for (var i = 0; i < tsArr.size() && i < closeArr.size(); i++) {
                var closeVal = closeArr[i];
                if (closeVal != null) {
                    var val = toFloat(closeVal);
                    if (val != null) {
                        var ts = tsArr[i];
                        var tsNum = 0;
                        if (ts instanceof Lang.Number) {
                            tsNum = ts as Lang.Number;
                        }
                        result.add(new DataPoint(tsNum, val as Lang.Float));
                    }
                }
            }
        } catch (ex) {
            System.println("Error parsing Yahoo history");
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
