$(document).ready(function() {
    $("input:checkbox").checkbox();
    $("#form_config").rpcform({
        success: function(a) {
            sbar.text("Configuration appliquée")
        },
        error: function(a) {
            sbar.error(null, "Impossible d'appliquer la configuration")
        }
    });
    $(".form_remove_redir").rpcform({
        success: function(a) {
            sbar.text("Redirection supprimée")
        },
        error: function(a) {
            sbar.error(null, "Impossible de supprimer la redirection")
        }
    });
    $("#redirs_list tbody").dynamiclist({
        jsonrpc: {
            method: "igd.redirs_get"
        },
        ejs: {
            url: "tpl/igd_redir.ejs",
            data: function(a) {
                return {
                    v: a
                }
            }
        },
        interval: 5000,
        jsonfield: function(a) {
            return a
        },
        jsonkey: function(a) {
            var b = "";
            if (a.ext_src_ip) {
                b = b + a.ext_src_ip
            }
            b = b + "/" + a.int_port + "/" + a.int_ip + "/" + a.proto;
            return b
        },
    })
});
