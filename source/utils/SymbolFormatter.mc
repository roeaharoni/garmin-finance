using Toybox.Lang;

class SymbolFormatter {

    // Replaces well-known currency codes with their symbols for display,
    // e.g. "USD/EUR" -> "$/€", "USD/ILS" -> "$/₪". Tokens that aren't known
    // currency codes pass through unchanged (e.g. "SPY", "BTC").
    static function prettify(name as Lang.String) as Lang.String {
        // Split on "/" manually (String.split is unavailable in Monkey C).
        var result = "";
        var current = "";
        for (var i = 0; i < name.length(); i++) {
            var ch = name.substring(i, i + 1);
            if (ch.equals("/")) {
                result += mapCode(current) + "/";
                current = "";
            } else {
                current += ch;
            }
        }
        result += mapCode(current);
        return result;
    }

    private static function mapCode(code as Lang.String) as Lang.String {
        if (code.equals("USD")) { return "$"; }
        if (code.equals("EUR")) { return "€"; }
        if (code.equals("ILS")) { return "₪"; }
        if (code.equals("GBP")) { return "£"; }
        if (code.equals("JPY")) { return "¥"; }
        return code;
    }
}
