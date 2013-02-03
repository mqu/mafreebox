$(document).ready(function() {
    $("input:checkbox").checkbox();
    $("#form_config").rpcform({
        success: function(a) {
            sbar.text("Configuration appliquée")
        },
        error: function(a) {
            sbar.error(null, a.error)
        }
    });
    $("#http_port").bind("keyup change", function() {
        var b = $("#http_port").val();
        var c = $("#ext_ip_address").val();
        var a = "http://" + c;
        if (b != 80) {
            a += ":" + b
        }
        a += "/";
        $("#ext_link").html(a);
        $("#ext_link").attr("href", a)
    });
    $("#http_enabled").click(function(b) {
        var c = b.target;
        var a = !c.checked;
        if (a) {
            $(".show_when_remote_access").show()
        } else {
            $(".show_when_remote_access").hide()
        }
    })
});
