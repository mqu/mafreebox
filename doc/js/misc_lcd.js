$(document).ready(function() {
    $("#form_scroll").css({
        visibility: "hidden"
    });
    $("#screen").css({
        opacity: lcd_brightness / 100
    });
    $("#lum").slider({
        value: lcd_brightness,
        max: 100,
        min: 10,
        slide: function(a, b) {
            $("#a").val(b.value);
            $("#percent span").html(b.value);
            $("#screen").css({
                opacity: b.value / 100
            })
        },
        stop: function(a, b) {
            $("#form_scroll").submit()
        }
    });
    $("#form_scroll").formrpc({
        success: function(a) {
            $(this).resetForm()
        }
    });
    $(":checkbox").checkbox();
    $(":checkbox[name=forced]").bind("check", function() {
        $("#div_force").show()
    });
    $(":checkbox[name=forced]").bind("uncheck", function() {
        $("#div_force").hide()
    });
    $("#form_rotation").rpcform({
        success: function(a) {
            sbar.text("Modifications effectuées")
        },
        error: function(a) {
            sbar.error(null, a.error)
        }
    })
});
