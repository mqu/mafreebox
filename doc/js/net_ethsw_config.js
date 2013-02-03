$(document).ready(function() {
    $("#form_config").rpcform({
        beforeSubmit: function(b, a) {
            for (i = 1; i <= 4; ++i) {
                speed = $("#port_" + i + "_speed").val();
                duplex = $("#port_" + i + "_duplex").val();
                if (speed == "1000" && duplex == "half") {
                    sbar.error(null, "Sur le port " + i + ": le mode Half-Duplex n'est pas supporté lorsque la vitesse est 1000MBits/s");
                    return false
                }
            }
        },
        success: function(a) {
            sbar.text("Configuration appliquée")
        },
        error: function(a) {
            sbar.error(null, "Impossible d'appliquer la configuration")
        }
    })
});
