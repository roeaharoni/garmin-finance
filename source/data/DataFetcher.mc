using Toybox.Lang;
using Toybox.System;

class DataFetcher {
    private var _provider;
    private var _cache as DataCache;
    private var _pendingSymbol as Lang.String?;
    private var _pendingCallback;

    function initialize() {
        _provider = ProviderFactory.getProvider();
        _cache = new DataCache();
        _pendingSymbol = null;
        _pendingCallback = null;
    }

    function fetchSymbol(symbol as Lang.String, callback) as Void {
        _pendingSymbol = symbol;
        _pendingCallback = callback;
        _provider.fetchQuote(symbol, method(:onDataReceived));
    }

    function onDataReceived(data as Lang.Dictionary?) as Void {
        if (data != null && _pendingSymbol != null) {
            var sym = _pendingSymbol as Lang.String;
            var d = data as Lang.Dictionary;
            _cache.store(sym, d.get("value") as Lang.Float, d.get("change") as Lang.Float);
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
