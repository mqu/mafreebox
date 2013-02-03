function update_ports_counters() {
    var a = [];
    for (index = 0; index < 4; index++) {
        a[index] = {
            method: "ethsw.port_counters",
            data: index + 1
        }
    }
    $.jsonrpc({
        url: "ethsw.cgi",
        batch: a,
        success: function(b) {
            if (!b) {
                return
            }
            for (i = 0; i < 4; ++i) {
                ejs.get("tpl/net_ethsw_port_stats_counters.ejs", {
                    port_id: i + 1,
                    counter: b[i],
                }, function(c) {
                    $("#port_" + (i + 1) + "_counters").html(c)
                })
            }
        }
    })
}
$(document).ready(function() {
    $("#port_stats_accordion").accordion({
        collapsible: true
    });
    setInterval(update_ports_counters, 5000)
});
