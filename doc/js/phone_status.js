function update_ring(b, a) {
    if (a) {
        sbar.text("Votre téléphone devrait sonner");
        b.active.value = "0";
        b.config.value = "Arrêter la sonnerie"
    } else {
        sbar.text("Arrêt de la sonnerie...");
        b.active.value = "1";
        b.config.value = "Faire sonner"
    }
}
$(document).ready(function() {
    $("input:checkbox").checkbox();
    $("#form_dect_reg").rpcform({
        success: function(a) {
            sbar.text("Modifications effectuées");
            setTimeout(document.location.reload, 2000)
        },
        error: function(a) {
            sbar.error(null, a.error)
        },
        beforeSubmit: function(d, a) {
            var c = a[0];
            var b = /^\d{4}$/;
            if (c.pin_dect && !b.test(c.pin_dect.value)) {
                sbar.error(null, "Code pin DECT invalide");
                return false
            }
        }
    });
    $("#form_fxs_ring").formrpc({
        success: function() {
            var a = $(this)[0];
            update_ring(a, a.active.value == "1");
            setTimeout(function() {
                $.jsonrpc({
                    method: "phone.fxs_ring",
                    active: "0",
                    success: function() {
                        update_ring(a, false)
                    }
                })
            }, 10000)
        },
        error: function() {
            sbar.error(null, "Échec de l'action.")
        }
    });
    $(".vendor_select").change(function(b) {
        var a = b.target;
        $.jsonrpc({
            method: "phone.dect_set_vendor",
            data: {
                vendor_id: $(a).val(),
                dect_id: $(a.form).find("[name=dect]").val()
            },
            active: "0",
            success: function(c) {
                if (c) {
                    sbar.text("Modifications effectuées")
                } else {
                    sbar.error(null, "Erreur lors de la sauvegarde du réglage")
                }
            }
        })
    });
    $("#form_fxs_gain").formrpc({
        success: function(a) {
            sbar.text("Modifications effectuées")
        },
        error: function(a) {
            sbar.error(null, "Erreur lors du réglage du volume")
        }
    });
    $("#gain_rx_slide").slider({
        value: $("#gain_rx").val(),
        max: 100,
        min: 1,
        slide: function(a, b) {
            $("#gain_rx").val(b.value)
        },
        stop: function(a, b) {
            $("#form_fxs_gain").submit()
        }
    });
    $("#gain_tx_slide").slider({
        value: $("#gain_tx").val(),
        max: 100,
        min: 1,
        slide: function(a, b) {
            $("#gain_tx").val(b.value)
        },
        stop: function(a, b) {
            $("#form_fxs_gain").submit()
        }
    })
});
