using Toybox.Lang;
using Toybox.Application;
using Toybox.System;

class ProviderFactory {

    // Maps numeric settings value to provider instance
    // 0 = Twelve Data (default), 1 = Alpha Vantage, 2 = Yahoo Finance
    static function getProvider() {
        var providerIndex = 0;

        try {
            var val = Application.getApp().getProperty("dataProvider");
            if (val != null && val instanceof Lang.Number) {
                providerIndex = val as Lang.Number;
            }
        } catch (ex) {
            System.println("Could not read dataProvider setting, using default");
        }

        System.println("Creating provider index: " + providerIndex);

        if (providerIndex == 1) {
            return new AlphaVantageProvider();
        } else if (providerIndex == 2) {
            return new YahooFinanceProvider();
        } else {
            return new TwelveDataProvider();
        }
    }
}
