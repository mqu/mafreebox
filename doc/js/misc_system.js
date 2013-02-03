$(document).ready(function() {
    $("#form_reboot").formrpc({
        success: function(a) {
            document.location.href = "/reboot.php"
        }
    })
});
