<?php

/* author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

FTP
Types :
ftp_config
    enabled               booléen 	Le serveur est activé ou non.
    allow_anonymous       booléen 	Les connections anonymes sont autorisées en lecture seule.
    allow_anonymous_write booléen 	De plus, les invitées ont le droit d'écrire.

Méthodes
- ftp.get_config () Récupére la configuration du serveur ftp.
  retour: Un objet de type ftp_config.

- ftp.set_config (cfg) Change la configuration du serveur ftp.
  - paramêtres en entrée:
    - cfg ftp_config 	

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


?>
