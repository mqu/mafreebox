<?php


/* author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

Phone : Téléphonie : Contrôle de la ligne téléphonique analogique et de la base DECT.

todo : 
- exploiter le journal des appels au format HTML et l'exporter dans un format utilisable (xml, csv, ...) /done.

methods :

    phone.status : Récupère l'état du matériel et de la ligne téléphonique. 
    phone.fxs_ring(active:bool) : Active/désactive la sonnerie du combiné de la ligne analogique. 
    phone.dect_paging(active:bool) : Active la recherche (sonnerie) de satellites DECT. 
    phone.dect_registration_set(active:bool) : Active ou désactive l'association de la base DECT de la freebox. 
    phone.dect_params_set(params) : Modifie les réglages d'enregistrement dect DECT 
    phone.dect_delete(id): Supprime les associations de tous les satellites de la base DECT de la freebox. 

extra-methods :

- Phone::logs() : retourne la liste des appels téléphonique sous forme :
	array:
	 - calls(list : log-record) : liste des appels passés.
	 - received(list : log-record) : liste des appels recus


data types :

log-record:
- [date] => string : date et heure
- [name] => phone number or name
- [number] => phone-number
- [duration] => durée ou appel manqué


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

require('lib/simplehtmldom.php'); # parser HTML

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
	
	# retourne le journal des appels recus et émis.
	public function logs(){
		$html =new simple_html_dom($this->fb->uri_get('/settings.php?page=phone_calls'));
		$list =array(
			'calls'    => array(),
			'received' => array()
		);
		/* XPATH 
		 * appels passés : //table[2].bloc/tr
		 * recus :  //table[1].bloc/tr
		 */
		# $tr = $html->find("/html/body/div[4]/div[3]/table[2]/tr"); # recus
		# FIXME : les appels passés et recus sont mélangés et renvoyés dans $list[received|calls] sans distinction
		# le code Ruby avec les mêmes expressions est fonctionnel.
		$tr = $html->find("//table[1].bloc/tr");  # les appels
		foreach($tr as $hr){
			$td = $hr->find('td');
			$list['received'][] = array(
				'date'     => $td[0]->innertext,
				'name'     => $td[1]->innertext,
				'number'   => $td[2]->innertext,
				'duration' => $td[3]->innertext,
			);
		}

		$tr = $html->find("//table[2].bloc/tr");  # les appels
		foreach($tr as $hr){
			$td = $hr->find('td');
			$list['calls'][] = array(
				'date'     => $td[0]->innertext,
				'name'     => $td[1]->innertext,
				'number'   => $td[2]->innertext,
				'duration' => $td[3]->innertext,
			);
		}
		
		return($list);
	}
}


?>
