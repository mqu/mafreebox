function lan_mode_to_french(b) {
    var a = {
        router: "Routeur",
        bridge: "Bridge",
    };
    if (a[b]) {
        return a[b]
    }
    return "Routeur"
}
$(document).ready(function() {
    $("#form_config").rpcform({
        beforeSubmit: function(b, a) {
            return true
        },
        success: function(a) {
            sbar.text("Configuration appliquée");
            $("#current_lan_mode").text(lan_mode_to_french($("#lan_mode").attr("value")))
        },
        error: function(a) {
            sbar.error(null, "Impossible de d'appliquer la configuration")
        }
    })
});
