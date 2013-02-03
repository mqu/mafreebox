$(document).ready(function() {
    $("input:checkbox").checkbox();
    $("#form_config").rpcform({
        success: function(a) {
            sbar.text("Modifications effectuées")
        },
        error: function(a) {
            $(this).resetForm();
            sbar.error(null, a.error)
        }
    });
    $("#button_restore").click(function() {
        $("#wifi_enabled").attr("checked", true);
        $("#wifi_hide_ssid").attr("checked", false);
        $("#wifi_ssid").val($("#wifi_def_ssid").val());
        $("#wifi_key").val($("#wifi_def_key").val());
        $("#wifi_wps").attr("checked", false);
        $("#wifi_encryption").val("wpa2_psk_auto");
        $("#wifi_mac_filter").val("disabled")
    })
});
