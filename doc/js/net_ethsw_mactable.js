$(document).ready(function() {
    $("#mac_address_table").dynamiclist({
        jsonrpc: {
            method: "ethsw.mac_address_table",
        },
        ejs: {
            url: "tpl/net_ethsw_mac_address_table_entry.ejs",
            data: function(a) {
                return {
                    entry: a
                }
            },
        },
        interval: 1000,
        key: "mac_addr",
        jsonfield: function(b) {
            return b
        },
        filter: function(a) {
            return true
        },
    })
});
