<?php

error_reporting(E_ALL);

function get_arg($idx=1, $default=false){
	if(isset($_SERVER["argv"][$idx]))
		return $_SERVER["argv"][$idx];
	return $default;
		
}

var_dump(get_arg(1, 'day'));

	$list=<<<EOF
	js/conn_config_adblock.js
	js/conn_config_ping.js
	js/conn_config_remote.js
	js/conn_config_wol.js
	js/conn_ddns_config.js
	js/conn_ddns_state.js
	js/conn_dsl_historic.js
	js/conn_dsl_stats.js
	js/conn_ftth_state.js
	js/conn_historic.js
	js/conn_status.js
	js/json2.js
	js/misc_lcd.js
	js/misc_system.js
	js/misc_testrate.js
	js/nas_afp.js
	js/nas_ftp.js
	js/nas_share.js
	js/nas_storage.js
	js/nas_upnpav.js
	js/net_dhcp_conf.js
	js/net_ethsw_config.js
	js/net_ethsw_graphs.js
	js/net_ethsw_mactable.js
	js/net_ethsw_state.js
	js/net_ethsw_stats.js
	js/net_fbxrop.js
	js/net_igd.js
	js/net_ipv6.js
	js/net_lan_ip.js
	js/net_lanmode.js
	js/net_lan_name.js
	js/net_lfilter_config.js
	js/net_lfilter_entries.js
	js/net_redirs_simple.js
	js/phone_calls.js
	js/phone_status.js
	js/settings.js
	js/utils.js
	js/wifi_client_aparams.js
	js/wifi_client_params.js
	js/wifi_client_station.js
	js/wifi_conf.js
	js/wifi_freewifi_params.js
	/doc/index.html
	/doc/account.html
	/doc/dhcp.html
	/doc/download.html
	/doc/fs.html
	/doc/ftp.html
	/doc/fw.html
	/doc/igd.html
	/doc/ipv6.html
	/doc/lan.html
	/doc/lcd.html
	/doc/phone.html
	/doc/share.html
	/doc/storage.html
	/doc/system.html
	/doc/user.html
	/doc/wifi.html
EOF;

print_r(split("\n",$list));

?>
