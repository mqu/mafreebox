<?php

/* author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

Phone : Téléphonie : Contrôle de la ligne téléphonique analogique et de la base DECT.

methods :

    phone.status : Récupère l'état du matériel et de la ligne téléphonique. 
    phone.fxs_ring(active:bool) : Active/désactive la sonnerie du combiné de la ligne analogique. 
    phone.dect_paging(active:bool) : Active la recherche (sonnerie) de satellites DECT. 
    phone.dect_registration_set(active:bool) : Active ou désactive l'association de la base DECT de la freebox. 
    phone.dect_params_set(params) : Modifie les réglages d'enregistrement dect DECT 
    phone.dect_delete(id): Supprime les associations de tous les satellites de la base DECT de la freebox. 

data types :

fxs-status:
- initializing 	En cours d'initialisation.
- working 	Fonctionnement normal.
- error 	Problème logiciel ou matériel empêchant la ligne de fonctionner.

mgcp-status:
- waiting 	Attend l'activation de la connexion internet, ou d'une configuration valide pour pouvoir se connecter aux serveurs.
- connecting 	En cours de connexion aux serveurs.
- working 	Fonctionnement normal.
- error 	Une erreur empêche la ligne de fonctionner (serveurs injoignable, mauvaise configuration, ...)

dect-params:
- enabled] => bool
- nemo_mode] => 
- ring_on_off] => bool
- eco_mode] => 
- pin] => 1234 (code pin)
- registration => 
- ring_type => int

phone-status :
(
    [mgcp] => Array  (ligne VOIP)
        (
            [status] => mgp-status
        )

    [fxs] => Array (ligne analogique)
        (
            [is_ringing] => boold
            [hook] => on|off     (état du combiné)
            [status] => fxs-status
            [gain_tx] => int
            [gain_rx] => int
        )

    [dects] => Array (liste des téléphones DECT déclarés)
        (
        )

    [dect] => dect-params

)

*/

class Phone {
	protected $fb;
	public function __construct($fb){
		$this->fb = $fb;
	}
	public function status(){
		return $this->fb->exec('phone.status');
	}
	# faire sonner le téléphone.
	public function fxs_ring($bool){
		return $this->fb->exec('phone.fxs_ring', $bool);
	}
	
	#  Active la recherche (sonnerie) de satellites DECT.
	public function dect_paging($bool=true){
		return $this->fb->exec('phone.dect_paging', $bool);
	}
	
	# Active ou désactive l'association de la base DECT de la freebox. 
	public function dect_registration_set($bool=true){
		return $this->fb->exec('phone.dect_registration_set', $bool);
	}
	
	# Modifie les réglages d'enregistrement DECT 
	public function dect_params_set($args){
		return $this->fb->exec('phone.dect_params_set', $args);
	}
	
	# Supprime les associations de (tous?) les satellites de la base DECT de la freebox. 
	public function dect_delete($id){
		return $this->fb->exec('phone.dect_delete', $id);
	}
}


?>
