function strchrs(b, a) {
    for (i = 0; i < a.length; ++i) {
        if (b.indexOf(a.charAt(i)) >= 0) {
            return true
        }
    }
    return false
}
function set_error(a, b) {
    if (a == null) {
        return
    }
    a[0].str = b
}
function check_login_name(c, b, d) {
    var a = ":";
    if (c.length < 1) {
        set_error(b, d + " ne doit pas être vide.");
        return false
    }
    if (c.length > 128) {
        set_error(b, d + " ne doit pas dépasser 128 caractères.");
        return false
    }
    if (strchrs(c, a)) {
        set_error(b, d + " ne doit pas contenir le caractère :");
        return false
    }
    return true
}
function check_login_password(b, a, c) {
    if (b.length > 32) {
        set_error(a, c + " ne doit pas faire plus de 32 caractères.");
        return false
    }
    return true
}
$(document).ready(function() {
    $("#form_config").rpcform({
        beforeSubmit: function(d, a) {
            var c = {};
            var b = a[0];
            if (!check_login_name($("#afp_login_name").val(), [c], "Le nom d'utilisateur")) {
                sbar.error(null, c.str);
                return false
            }
            if (!check_login_password($("#afp_login_password").val(), [c], "Le mot de passe")) {
                sbar.error(null, c.str);
                return false
            }
            return true
        },
        success: function(a) {
            sbar.text("Configuration appliquée")
        },
        error: function(a) {
            sbar.error(null, "Impossible d'appliquer la configuration")
        }
    });
    $("input:checkbox").checkbox();
    $("#afp_enabled").click(function(b) {
        var c = b.target;
        var a = !c.checked;
        if (a) {
            $("#show_when_afp_enabled").show()
        } else {
            $("#show_when_afp_enabled").hide();
            if (!check_login_name($("#afp_login_name").val())) {
                $("#afp_login_name").val("freebox")
            }
            if (!check_login_password($("#afp_login_password").val())) {
                $("#afp_login_password").val("")
            }
        }
    });
    $("#afp_guest_allow").click(function(b) {
        var c = b.target;
        var a = !c.checked;
        if (!a) {
            $("#show_when_afp_guest_disallowed").show()
        } else {
            $("#show_when_afp_guest_disallowed").hide();
            if (!check_login_name($("#afp_login_name").val())) {
                $("#afp_login_name").val("freebox")
            }
            if (!check_login_password($("#afp_login_password").val())) {
                $("#afp_login_password").val("")
            }
        }
    })
});
