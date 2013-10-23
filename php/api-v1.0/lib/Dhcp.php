<?php

/*
 * author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

Dhcp : Serveur DHCP : Fonctions permettant d'interagir avec le serveur DHCP.

    dhcp.status_get : Retourne l'état du serveur dhcp. 
    dhcp.leases_get : Retourne la liste des baux DHCP courants. 
    dhcp.sleases_get : Retourne la liste des baux statiques configurés. 
    dhcp.config_get -> dhcp-config : récupère la configuration du serveur DHCP
    dhcp.config_set (dhcp-config) : Modifie la configuration du serveur DHCP 
    dhcp.slease_add (mac, ip, comment) : ajoute un bail statique 
    dhcp.slease_del (mac) : Supprime un bail statique 

dhcp-config:

    [enabled] => bool
    [sticky_assign] => bool
    [ip_range] => Array
        (
            [0] => ip-start
            [1] => ip-end
        )

    [netmask] => net-mask
    [gateway] => ip
    [always_broadcast] => bool
    [dns] => Array
        (
            [0] => ip1
        )

*/

class Dhcp {
	protected $fb;
	public function __construct($fb){
		$this->fb = $fb;
	}
	
	public function status_get(){
		return $this->fb->exec('dhcp.status_get');
	}

	public function leases_get(){
		return $this->fb->exec('dhcp.leases_get');
	}
	public function sleases_get(){
		return $this->fb->exec('dhcp.sleases_get');
	}

	# return an array (params) of ...
	public function config_get(){
		return $this->fb->exec('dhcp.config_get');
	}

	public function config_set($params){
		return $this->fb->exec('dhcp.config_set', $params);
	}

	public function slease_add($mac, $ip, $comment){
		return $this->fb->exec('dhcp.slease_add', array($mac, $ip, $comment));
	}
	public function slease_del($mac){
		return $this->fb->exec('dhcp.slease_del', $mac);
	}
}
?>
