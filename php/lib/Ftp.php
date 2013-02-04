<?php

/* author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

FTP : Fonctions permettant d'interagir avec le serveur FTP.


Types :

ftp-config
- enabled               booléen 	Le serveur est activé ou non.
- allow_anonymous       booléen 	Les connections anonymes sont autorisées en lecture seule.
- allow_anonymous_write booléen 	De plus, les invitées ont le droit d'écrire.


Méthodes:

ftp.get_config (config:ftp-config) Récupére la configuration du serveur ftp.
ftp.set_config (config:ftp-config) Change la configuration du serveur ftp.


*/

class Ftp{
	protected $fb;
	public function __construct($fb){
		$this->fb = $fb;
	}

	public function get_config(){
		return $this->fb->exec('ftp.get_config');
	}

	public function set_config($cfg){
		return $this->fb->exec('set.set_config', $cfg);
	}
}

/*

usage :

$freebox = new Mafreebox('http://mafreebox.freebox.fr', 'freebox', 'mon.mdp');

print_r($cnf = $freebox->ftp->get_config());
# $cnf['enabled'] = 1;
# $cnf['allow_anonymous'] = 1;
# $cnf['allow_anonymous_write'] = 1;
# $cnf['password'] = '123456';
$cnf = $freebox->ftp->get_config($cnf);

*/

?>
