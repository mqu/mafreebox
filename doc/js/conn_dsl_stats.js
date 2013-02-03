function graph_refresh(b, a) {
    if (b.is(".open")) {
        rrdgraph_load(b, a, false)
    }
}
$(document).ready(function() {
    var c = $("#graph_snr");
    var e = $("#graph_rate_down");
    var a = $("#graph_rate_up");
    var b = getQueryParams(document.location.search);
    var d = b.period;
    setInterval(function() {
        graph_refresh(c, "db=fbxdsl&type=snr&period=" + d);
        graph_refresh(a, "db=fbxdsl&type=rate&dir=up&period=" + d);
        graph_refresh(e, "db=fbxdsl&type=rate&dir=down&period=" + d)
    }, 5000)
});
