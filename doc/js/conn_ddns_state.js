$(document).ready(function() {
    $("#providers").dynamiclist({
        jsonrpc: {
            method: "ddns.providers"
        },
        ejs: {
            url: "tpl/conn_ddns_provider_status.ejs",
            data: function(a) {
                return {
                    provider: a
                }
            }
        },
        filter: function(a) {
            return a.cfg.enabled == true
        },
        interval: 1000,
        key: "name",
        jsonfield: function(b) {
            return b
        },
        ejs_update_if_present: true
    })
});
