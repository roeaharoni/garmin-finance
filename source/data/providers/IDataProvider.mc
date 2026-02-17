using Toybox.Lang;

class IDataProvider {
    function fetchQuote(symbol as Lang.String, callback as Lang.Method) as Void {}

    function fetchHistory(symbol as Lang.String, callback as Lang.Method) as Void {}

    function requiresApiKey() as Lang.Boolean {
        return false;
    }

    function getApiKeyInstructions() as Lang.String {
        return "";
    }

    function getName() as Lang.String {
        return "Unknown";
    }

    function getAlias() as Lang.String {
        return "unknown";
    }
}
