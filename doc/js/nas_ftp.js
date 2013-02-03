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
    $("#allow_anonymous").click(function(b) {
        var c = b.target;
        var a = !c.checked;
        if (a) {
            $("#anon_write_fields").show()
        } else {
            $("#anon_write_fields").hide()
        }
    })
});
