<?php

/* author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

Phone : Téléphonie : Contrôle de la ligne téléphonique analogique et de la base DECT.

    phone.status
    phone.fxs_ring
    phone.dect_paging
    phone.dect_registration_set
    phone.dect_params_set
    phone.dect_delete
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
