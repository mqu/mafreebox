function graph_refresh(b, a) {
    if (b.is(".open")) {
        rrdgraph_load(b, "db=fbxconnman&dir=" + a, false)
    }
}
function conn_refresh(f) {
    var b = $("#conn_state").attr("val");
    var c = $("#conn_media").attr("val");
    var e = $("#conn_type").attr("val");
    var a = $("#conn_ident").attr("val");
    if (!f) {
        return
    }
    if (f.state != b || (c && f.media != c) || (e && f.type != e) || (a && f.ident != a)) {
        window.location.reload(true);
        return
    }
    if (f.state != "up") {
        return
    }
    f.bytes_up = format_size(f.bytes_up);
    f.bytes_down = format_size(f.bytes_down);
    f.rate_up = format_rate(f.rate_up);
    f.rate_down = format_rate(f.rate_down);
    f.bandwidth_up = format_rate(f.bandwidth_up / 8);
    f.bandwidth_down = format_rate(f.bandwidth_down / 8);
    $("#conn_ipaddr").text(f.ip_address);
    $("#conn_bytes_down").text(f.bytes_down);
    $("#conn_bytes_up").text(f.bytes_up);
    $("#conn_rate_down").text(f.rate_down + " (max " + f.bandwidth_down + ")");
    $("#conn_rate_up").text(f.rate_up + " (max " + f.bandwidth_up + ")")
}
$(document).ready(function() {
    var d = $("#graph_rate_down");
    var a = $("#graph_rate_up");
    var b = getQueryParams(document.location.search);
    var c = b.period;
    setInterval(function() {
        graph_refresh(a, "up&period=" + c);
        graph_refresh(d, "down&period=" + c)
    }, 5000);
    setInterval(function() {
        $.jsonrpc({
            method: "conn.status",
            success: conn_refresh
        })
    }, 1000)
});
