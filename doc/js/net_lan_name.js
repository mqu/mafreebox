var unaccented = "AAAAAAACEEEEIIIIDNOOOOO.OUUUUY..aaaaaaaceeeeiiiidnooooo.ouuuuy.yAaAaAaCcCcCcCcDdDdEeEeEeEeEeGgGgGgGgHhHhIiIiIiIiIiIiJjKkkLlLlLlLlJlNnNnNnnNnOoOoOoOoRrRrRrSsSsSsSsTtTtTtUuUuUuUuUuUuWwYyYZzZzZz.";
var invalid = "\"'\\@<>{}[]$%&";

function stripaccents(e) {
    var d = "";
    for (var a = 0; a < e.length; a++) {
        var c = e[a];
        var b = c.charCodeAt(0) - 192;
        if (b >= 0 && b < stripstring.length) {
            var f = stripstring.charAt(b);
            if (f != ".") {
                c = f
            }
        }
        d += c
    }
    return d
}
var charlen = function(b) {
        var a = 0;
        b = b.toLowerCase();
        for (var d = 0; d < b.length; ++d) {
            var e = b.charAt(d);
            if (e > "z") {
                continue
            }
            if (e < "a" && e > "9") {
                continue
            }
            if (e < "0") {
                continue
            }
            a++
        }
        return a
    };
var validate_name = function(a) {
        var c = charlen(a);
        if (a.length > 63) {
            return "Nom trop long"
        }
        for (var b = 0; b < a.length; b++) {
            if (invalid.indexOf(a.charAt(b)) != -1) {
                return "Nom invalide"
            }
        }
        if (c < 3) {
            return "Nom contenant trop peu de lettres"
        }
        return undefined
    };
var sanitize_name = function(b, g, f, j) {
        var a = "";
        for (var d = 0; d < b.length; ++d) {
            if (a.length >= f) {
                break
            }
            var h = b.charAt(d);
            var e = h.charCodeAt(0) - 192;
            if (e >= 0 && e < unaccented.length) {
                h = unaccented.charAt(e)
            }
            if (g.indexOf(h.toLowerCase()) != -1) {
                a = a + h
            } else {
                if (a.length > 0 && a.charAt(a.length - 1) != j) {
                    a = a + j
                }
            }
        }
        if (a.charAt(a.length - 1) == j) {
            a = a.substr(0, a.length - 1)
        }
        return a
    };
var sanitize_dns = function(a) {
        return sanitize_name(a, "0123456789-abcdefghijklmnopqrstuvwxyz", 63, "-")
    };
var sanitize_netbios = function(a) {
        return sanitize_name(a, "!#$%&'()+,-.0123456789;=@abcdefghijklmnopqrstuvwxyz[]^_`{}~", 15, "_")
    };
$(document).ready(function() {
    $("#form_config").rpcform({
        beforeSubmit: function(f, c) {
            var e = c[0];
            var a = $("#box_name").val();
            var d = validate_name(a);
            if (d) {
                sbar.error(null, d);
                return false
            }
            var b = $("#box_name_netbios").val();
            if (b != sanitize_netbios(b)) {
                sbar.error(null, "Nom Netbios invalide");
                return false
            }
            var b = $("#box_name_dns").val();
            if (b != sanitize_dns(b)) {
                sbar.error(null, "Nom DNS invalide");
                return false
            }
            return true
        },
        success: function(a) {
            sbar.text("Modifications effectuées")
        },
        error: function(a) {
            sbar.error(null, a.error)
        }
    });
    $("#box_name").keyup(function(d) {
        var b = $(this).val();
        var a = $("#box_name").val();
        var c = validate_name(a);
        $(this).toggleClass("bad_input", (a.length > 2) && (c != undefined));
        $("#box_name_netbios").val(sanitize_netbios(b));
        $("#box_name_dns").val(sanitize_dns(b.toLowerCase()));
        $("#box_name_netbios").removeClass("bad_input");
        $("#box_name_dns").removeClass("bad_input")
    });
    $("#box_name_netbios").keyup(function(b) {
        var a = $(this).val();
        $(this).toggleClass("bad_input", (a != sanitize_netbios(a)))
    });
    $("#box_name_dns").keyup(function(b) {
        var a = $(this).val();
        $(this).toggleClass("bad_input", (a != sanitize_dns(a)))
    })
});
