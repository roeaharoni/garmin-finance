using Toybox.Communications;
using Toybox.Lang;

class HttpUtil {

    static function makeGetRequest(url as Lang.String, params as Lang.Dictionary, callback as Lang.Method) as Void {
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, params, options, callback);
    }

    static function buildQueryString(params as Lang.Dictionary) as Lang.String {
        var query = "";
        var keys = params.keys();

        for (var i = 0; i < keys.size(); i++) {
            var key = keys[i];
            var value = params[key];

            if (i > 0) {
                query += "&";
            }

            query += key + "=" + value;
        }

        return query;
    }
}
