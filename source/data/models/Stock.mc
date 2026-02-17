using Toybox.Lang;

class Stock extends FinanceSymbol {
    private var _companyName as Lang.String?;
    private var _exchange as Lang.String?;

    function initialize(name as Lang.String) {
        FinanceSymbol.initialize(name);
        _companyName = null;
        _exchange = null;
    }

    function getCompanyName() as Lang.String? {
        return _companyName;
    }

    function setCompanyName(name as Lang.String?) as Void {
        _companyName = name;
    }

    function getExchange() as Lang.String? {
        return _exchange;
    }

    function setExchange(exchange as Lang.String?) as Void {
        _exchange = exchange;
    }
}
