$(document).ready(function() {
    $("#form_clear_histo").formrpc({
        success: function() {
            $("#tbl_histo tbody").empty();
            return false
        }
    })
});
