<?php

/* author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

Fw : Firewall : Fonctions permettant d'interagir avec le firewall.
    fw.wan_redirs_get():array(wan-redir-entry) :  Retourne la liste des redirections de ports. 
    fw.wan_range_redirs_get() :  Retourne la liste des redirections de plage de ports. 
    fw.wan_redir_del(id):  Supprime une redirection de port. 
    fw.wan_range_redir_del(id):  Supprime une redirection de plage de port. 
    fw.wan_redir_add(params):  Ajoute une redirection de port : params de type wan-redir-entry ?
    fw.wan_range_redir_add(params):  Ajoute une redirection de port. 
    fw.dmz_get():dmz-cfg:  Retourne la configuration DMZ 
    fw.dmz_set(dmz-cfg):  Applique la configuration DMZ 
    fw.lfilter_config_get():filter-params :  Retourne la configuration du contrôle parental 
    fw.lfilter_config_set(filter-params):  Applique la configuration du contrôle parental 
    fw.lfilters_get():array(filter-entry-params)  Retourne la liste des filtres de contrôle parental actifs 
    fw.lfilter_add(filter-entry-params):  Ajoute un filtre de contrôle parental 
    fw.lfilter_del(id):  Supprime un filtre de contrôle parental 

types:

wan-redir-entry:
- [lan_ip] => lan-ip
- [comment] => string
- [ip_proto_name] => udp
- [id] => integer
- [lan_port] => integer
- [wan_port] => integer
- [ip_proto] => integer

dmz-cfg:



*/

class Fw {
	protected $fb;
	public function __construct($fb){
		$this->fb = $fb;
	}
	public function wan_redirs_get(){
		return $this->fb->exec('fw.wan_redirs_get');
	}
	public function wan_range_redirs_get(){
		return $this->fb->exec('fw.wan_range_redirs_get');
	}
	public function dmz_get(){
		return $this->fb->exec('fw.dmz_get');
	}
	public function lfilter_config_get(){
		return $this->fb->exec('fw.lfilter_config_get');
	}
	public function lfilters_get(){
		return $this->fb->exec('fw.lfilters_get');
	}

}
?>
