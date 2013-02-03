<?php

/*
 * author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

Dhcp : Serveur DHCP : Fonctions permettant d'interagir avec le serveur DHCP.

    dhcp.status_get
    dhcp.leases_get
    dhcp.sleases_get
    dhcp.config_get -> params
    dhcp.config_set (params)
    dhcp.slease_add (mac, ip, comment)
    dhcp.slease_del (mac)
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
	
	# dhcp.slease_add (mac, ip, comment)
	# dhcp.slease_del (mac)
}
?>
