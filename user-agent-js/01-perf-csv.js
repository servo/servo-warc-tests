function printPerfTiming() {
    var dateTime = new Date().toISOString();
    var date = dateTime.substring(0, 10);
    var isTopLevel = (window.parent === window);
    console.log(
        "\nWARC," +
            date                                   + "," +
            window.location                        + "," +
            performance.timing.navigationStart     + "," +
            performance.timing.domLoading          + "," +
            performance.timing.domInteractive      + "," +
            performance.timing.topLevelDomComplete + "," +
            performance.timing.domComplete         + "," +
            performance.timing.loadEventStart      + "," +
            performance.timing.loadEventEnd        + "," +
            isTopLevel                             + "\n"
    );
    if (isTopLevel) { window.close(); }
}

if (document.readyState === "complete") {
    printPerfTiming();
} else {
    var timeout = 5;
    window.addEventListener('load', function () {
        window.setTimeout(printPerfTiming, 0);
    });
    window.setTimeout(function() {
        console.log("Timeout after " + timeout + " min. Force stop");
        window.close();
    }, timeout * 60 * 1000)
}
