counter = 0;

function update_ports() {
    var a = [];
    for (index = 0; index < 4; index++) {
        a[index] = {
            method: "ethsw.port_state",
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
                ejs.get("tpl/net_ethsw_port_state.ejs", {
                    port_index: i + 1,
                    state: b[i]
                }, function(c) {
                    $("#eth_port_" + (i + 1)).html(c)
                })
            }
        },
    });
    ++counter;
    setTimeout(update_ports, 1000)
}
$(document).ready(function() {
    setTimeout(update_ports, 1000)
});
