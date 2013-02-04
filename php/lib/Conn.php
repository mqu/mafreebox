<?php

/* author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 


Conn: informations concernant l'état de la connexion Internet et réponse au ping.

types:

conn-status:
- type: rfc2684
- state: up|down
- media: adsl|fibre?
- ip_address: ip externe

- rate_down: int (débit download instantané)
- rate_up: int (débit upload instantané)

- bytes_down: volume téléchargé (download) depuis reboot en octet
- bytes_up: volume téléchargé (upload) depuis reboot en octet

- bandwidth_up: bande passante en octets/s (upload)
- bandwidth_down: bande passante en octets/s (download)


log-type:
- [id] => int
- [type] => up
- [date] => time_t 
- [connection] => dgp_priv|dgp_pub : état de la connexion (publique ou privée) 


methods :

conn.status -> conn-status : état de la connexion Internet (débit instantané, bande passante, volumétrie, état).

conn.wan_ping_get : état de la réponse au ping sur l'adresse IP externe
conn.wan_ping_set(bool) : configuration de la réponse au ping

conn.remote_access_set(bool) : autorise l'accès à l'interface d'administration à distance (et le scripting),
conn.remote_access_get : configuration

conn.proxy_wol_get : état du proxy wakeup on lan (WOL)
conn.proxy_wol_set(bool) : configuration du proxy WOL

conn.logs : array(log-type) : historique de la connexion Internet : retrace les connexions et déconnexion.
conn.logs_flush : efface l'historique des connexions

conn.wan_adblock_get : état du blocage de la publicité
conn.wan_adblock_set(bool) : blocage de la publicité


*/

class Conn {
	protected $fb;
	public function __construct($fb){
		$this->fb = $fb;
	}
	public function status(){
		return $this->fb->exec('conn.status');
	}

	public function wan_ping_get(){
		return $this->fb->exec('conn.wan_ping_get')==true;
	}
	public function wan_ping_set($bool){
		return $this->fb->exec('conn.wan_ping_set', $bool);
	}

	public function proxy_wol_get(){
		return $this->fb->exec('conn.proxy_wol_get')==true;
	}
	public function proxy_wol_set($bool){
		return $this->fb->exec('conn.proxy_wol_set', $bool);
	}

	public function logs(){
		return $this->fb->exec('conn.logs');
	}
	public function logs_flush(){
		return $this->fb->exec('conn.logs_flush');
	}

	public function wan_adblock_get(){
		return $this->fb->exec('conn.wan_adblock_get')==true;
	}
	public function wan_adblock_set($bool){
		return $this->fb->exec('conn.wan_adblock_set', $bool);
	}

	public function remote_access_get(){
		return $this->fb->exec('conn.remote_access_get')==true;
	}
	public function remote_access_set($bool){
		return $this->fb->exec('conn.remote_access_set', $bool);
	}
}
?>
