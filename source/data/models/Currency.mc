using Toybox.Lang;

class Currency extends FinanceSymbol {
    private var _baseCurrency as Lang.String;
    private var _quoteCurrency as Lang.String;

    function initialize(name as Lang.String) {
        FinanceSymbol.initialize(name);

        var parts = parseCurrencyPair(name);
        _baseCurrency = parts[0] as Lang.String;
        _quoteCurrency = parts[1] as Lang.String;
    }

    function getBaseCurrency() as Lang.String {
        return _baseCurrency;
    }

    function getQuoteCurrency() as Lang.String {
        return _quoteCurrency;
    }

    private function parseCurrencyPair(pair as Lang.String) as Lang.Array {
        var slashIndex = -1;
        for (var i = 0; i < pair.length(); i++) {
            if (pair.substring(i, i + 1).equals("/")) {
                slashIndex = i;
                break;
            }
        }

        if (slashIndex > 0) {
            return [
                pair.substring(0, slashIndex),
                pair.substring(slashIndex + 1, pair.length())
            ];
        }

        return [pair, "USD"];
    }
}
