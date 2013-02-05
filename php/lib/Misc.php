<?php

/* author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

type:
ipv6-cnf:
- enabled : bool (true, false)

IPv6 : Fonctions permettant de configurer IPv6
    ipv6.config_get:ipv6-cnf
    ipv6.config_set(ipv6-cnf)

*/

class IPv6 {
	protected $fb;

	public function __construct($fb){
		$this->fb = $fb;
	}

	public function config_get(){
		return $this->fb->exec('ipv6.config_get');
	}
	public function config_set($cnf){
		return $this->fb->exec('ipv6.config_set', $cnf);
	}
}

/*
Lcd : Afficheur Fonctions permettant de controler l'afficheur de la Freebox.
    lcd.brightness_get:int (pourcentage)
    lcd.brightness_set(value:int)
*/

class Lcd {
	protected $fb;

	public function __construct($fb){
		$this->fb = $fb;
	}
	
	public function brightness_get(){
		return $this->fb->exec('lcd.brightness_get');
	}
	public function brightness_set($value){
		return $this->fb->exec('lcd.brightness_set', $value);
	}
}

/*
Share : Partage Windows : Fonctions permettant d'interagir avec la fonction de partage windows de la freebox.
    share.get_config:type-share-cnf
    share.set_config(type-share-cnf)

type-share-cnf:
- [workgroup] => string ; défaut=freebox
- [logon_password] => 
- [print_share_enabled] => 1
- [file_share_enabled] => 1
- [logon_enabled] => 
- [logon_user] => string ; defaut=freebox

*/

class Share {
	protected $fb;

	public function __construct($fb){
		$this->fb = $fb;
	}
	
	public function get_config(){
		return $this->fb->exec('share.get_config');
	}
	public function set_config($cnf){
		return $this->fb->exec('share.set_config', $cnf);
	}
}


/*
User : Utilisateurs : Permet de modifier les paramêtres utilisateur du boitier NAS.
    user.password_reset(login) : Réinitialize le mot de passe d'un utilisateur. 
    user.password_set(login, oldpass, newpass) : Change le mot de passe d'un utilisateur. 
    user.password_check_quality(passwd) : 
*/

class User {
	protected $fb;

	public function __construct($fb){
		$this->fb = $fb;
	}
	
	# Réinitialize le mot de passe d'un utilisateur.
	#
	# Pour changer le mot de passe sans avoir le précédent en sa possession, l'utilisateur doit être devant
	# sa freebox: un code généré aléatoirement sera affiché sur l'écran du NAS, qui devra être renseigné à 
	# la place de l'ancien mot de passe. Cette fonction génère une chaîne aléatoire et l'affiche à  l'écran 
	# (il n'est pas possible pour vous de la récupérer). Appelez ensuite "user.password_set" avec cette chaîne à  la place de "old_pass".
	public function password_reset($login){
		return $this->fb->exec('user.password_set', $login);
	}

	# Change le mot de passe d'un utilisateur.
	# oldpass est généré par la freebox après appel de password_reset()
	public function password_set($login, $oldpass, $newpass){
		return $this->fb->exec('user.password_set', array($login, $oldpass, $newpass));
	}

	public function password_check_quality($passwd){
		return $this->fb->exec('user.password_check_quality', $passwd);
	}
}


/*
Lan : Fonctions permettant de configurer le réseau LAN.
    lan.ip_address_get
    lan.ip_address_set
*/

class Lan {
	protected $fb;

	public function __construct($fb){
		$this->fb = $fb;
	}
	
	# retourne l'adresse IP courante de la Freebox sur le LAN.
	public function ip_address_get(){
		return $this->fb->exec('lan.ip_address_get');
	}
	
	# change l'adresse IP du la Freebox.
	public function ip_address_set($ip){
		return $this->fb->exec('lan.ip_address_set', $ip);
	}
}

?>
