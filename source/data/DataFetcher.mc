using Toybox.Lang;
using Toybox.System;

class DataFetcher {
    private var _provider;
    private var _cache as DataCache;
    private var _pendingSymbol as Lang.String?;
    private var _pendingCallback;
    private var _pendingHistorySymbol as Lang.String?;
    private var _pendingHistoryCallback;

    function initialize() {
        _provider = ProviderFactory.getProvider();
        _cache = new DataCache();
        _pendingSymbol = null;
        _pendingCallback = null;
        _pendingHistorySymbol = null;
        _pendingHistoryCallback = null;
    }

    function fetchSymbol(symbol as Lang.String, callback) as Void {
        _pendingSymbol = symbol;
        _pendingCallback = callback;
        _provider.fetchQuote(symbol, method(:onDataReceived));
    }

    function onDataReceived(data as Lang.Dictionary?) as Void {
        if (data != null && _pendingSymbol != null) {
            var sym = _pendingSymbol as Lang.String;
            _cache.store(sym, data as Lang.Dictionary);
            System.println("Cached data for " + sym);
            if (_pendingCallback != null) {
                _pendingCallback.invoke(data);
            }
        } else {
            System.println("Failed to fetch data");
            if (_pendingCallback != null) {
                _pendingCallback.invoke(null);
            }
        }
    }

    function fetchHistory(symbol as Lang.String, range as Lang.String, callback) as Void {
        _pendingHistorySymbol = symbol;
        _pendingHistoryCallback = callback;
        _provider.fetchHistory(symbol, range, method(:onHistoryReceived));
    }

    function onHistoryReceived(data as Lang.Array?) as Void {
        if (data != null && _pendingHistorySymbol != null && data.size() > 0) {
            var sym = _pendingHistorySymbol as Lang.String;
            _cache.storeHistory(sym, data as Lang.Array);
            System.println("Cached history for " + sym + " (" + data.size() + " points)");
        }
        if (_pendingHistoryCallback != null) {
            _pendingHistoryCallback.invoke(data);
        }
    }

    function getProviderName() as Lang.String {
        return _provider.getName();
    }

    function getProviderAlias() as Lang.String {
        return _provider.getAlias();
    }

    function requiresApiKey() as Lang.Boolean {
        return _provider.requiresApiKey();
    }
}
