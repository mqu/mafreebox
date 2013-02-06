<?php

/* author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

Wifi : 

WiFi : Fonctions permettant de paramétrer le réseau sans-fil.
    wifi.status_get() : Retourne l'état du réseau sans fil 
    wifi.config_get() : Retourne la configuration du réseau sans fil
    wifi.ap_params_set(params) : Modifie la configuration de la carte Wifi 
    wifi.bss_params_set(bss_cfg_name, params) : 
    wifi.mac_filter_add(bss_cfg_name, filter_type, mac, comment): Ajoute une entrée à  la liste des MACs autorisées/interdites 
    wifi.mac_filter_del(bss_cfg_name, filter_type, mac) :  Supprime une entrée de la liste des MACs autorisées/interdites 
    wifi.stations_get(bssid, enabled) : Retourne la liste des stations associées 

	- un examen rapide des requetes via Firebug montre que la configuration dans l'interface actuelle (1.1.9.1) ne passe pas par des requetes JSON.
	- il est cependant possible d'utiliser les requetes de lecture de configuration.
*/

class Wifi {
	protected $fb;
	public function __construct($fb){
		$this->fb = $fb;
	}

	public function status_get(){
		return $this->fb->exec('wifi.status_get');
	}
	public function config_get(){
		return $this->fb->exec('wifi.config_get');
	}
}

/*
 
print_r($this->status_get()) :
 
Array
(
    [bss] => Array
        (
            [perso] => Array
                (
                    [name] => perso
                    [params] => Array
                        (
                            [enabled] => 1
                            [ssid] => monssid
                            [encryption] => wpa_psk_tkip
                            [hide_ssid] => 
                            [allowed_macs] => Array
                                (
                                    [0] => Array
                                        (
                                            [mac] => 2C:B0:5D:5B:3C:38
                                            [comment] => netgear 802.11N
                                        )

                                    [1] => Array
                                        (
                                            [mac] => 00:08:10:75:B9:AB
                                            [comment] => apm
                                        )

                                )

                            [eapol_version] => 2
                            [key] => mot-de-passe-wifi
                            [denied_macs] => Array
                                (
                                    [0] => Array
                                        (
                                            [mac] => 00:1F:3C:1E:45:63
                                            [comment] => portable wifi interne.
                                        )

                                )

                            [wps] => Array
                                (
                                    [enabled] => 
                                )

                            [mac_filter] => disabled
                        )

                )

            [freewifi] => Array
                (
                    [name] => freewifi
                    [params] => Array
                        (
                            [enabled] => 1
                            [ssid] => FreeWifi
                            [encryption] => none
                            [hide_ssid] => 
                            [allowed_macs] => Array
                                (
                                )

                            [eapol_version] => 0
                            [key] => 
                            [denied_macs] => Array
                                (
                                )

                            [wps] => Array
                                (
                                    [enabled] => 
                                )

                            [mac_filter] => disabled
                        )

                )

        )

    [ap_params] => Array
        (
            [enabled] => 1
            [channel] => 6
            [wmm] => 1
            [ht] => Array
                (
                    [ht_mode] => disabled
                )

            [band] => g
        )

)

print_r($this->config_get()) :

Array
(
    [detected] => 1
    [bss] => Array
        (
            [perso] => Array
                (
                    [has_wps] => 
                    [bssid] => F4:CA:E5:C8:F1:70
                    [name] => perso
                    [active] => 1
                )

            [freewifi] => Array
                (
                    [has_wps] => 
                    [bssid] => F4:CA:E5:C8:F1:71
                    [name] => freewifi
                    [active] => 1
                )

        )

    [active] => 1
)

*/

?>
