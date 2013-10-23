<?php

/* author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

Download : Téléchargement : Gestionnaire de téléchargement ftp/http/torrent.


types :

dl-cfg:
- max_up: int
- download_dir : string, défaut : /Disque dur/Téléchargements
- max_dl: int
- max_peer: int
- seed_ratio: int

dl-type: Protocole utilisé par la tâche.
- torrent 	Téléchargement d'un fichier torrent.
- http 	Téléchargement d'un lien ftp.
- ftp 	TÃéléchargement d'un lien ftp.

dl-status :
- queued 	Tâche dans la file d'attente (en attente de téléchargement, uniquement http/ftp).
- running 	Tâche en cours de téléchargement.
- seeding 	Tâche en cours de diffusion (uniquement torrent).
- paused 	Tâche interrompue (en pause).
- done      Tâche terminée.
- error 	Une erreur s'est produite.

torrent_opts : Paramêtres en entree:
  opt: paramêtres pour l'ajout. Un seul de ces champs est nécessaire.
  - url (string): un lien http vers le fichier torrent.
  - magnet (string):  un lien torrent de type magnet link.
  - data (string): lLe contenu du fichier torrent, encodÃ© en base64.

task : 

	id: id
	type: dl-type
	transferred: bytes transfered
	name: filename
	errmsg: 
	status: dl-status
	url: ftp://... | http://...
	rx_rate: in bytes/s
	size: size to download in bytes

methods :
    download.start(type, id)
    download.stop(type, id)
    download.remove(type, id)
    download.torrent_add(torrent_opts)
    download.http_add(name, url)
    download.get(type, id)
    download.list->array[task]: retourne la liste des téléchargements en cours ou terminés
    download.config_get(->cfg:dl-cfg) :
    download.config_set(cfg:dl-cfg) :  Modifie la configuration utilisateur du module de téléchargement. 

	download.list()
		Récupère la liste de tous les téléchargements en cours et terminés.
		Retour: Un tableau d'objets de type task.

	download.config_get()
		Récupère la configuration utilisateur du module de téléchargement.
		Retour: Un objet de type dl-cfg.

	download.config_set (cfg:dl-cfg)
		Modifie la configuration utilisateur du module de téléchargement.
		Paramètres en entrée:

		cfg 	Options de configuration utilisateur.


*/
         


class Download{
	protected $fb;
	public function __construct($fb){
		$this->fb = $fb;
	}
	
	public function _list(){
		return $this->fb->exec('download.list');
	}

	public function config_get(){
		return $this->fb->exec('download.config_get');
	}
	public function config_set($cfg){
		return $this->fb->exec('download.config_set', $cfg);
	}
	public function http_add($name, $url){
		return $this->fb->exec('download.http_add', array($name, $url));
	}
	public function start($type, $id){
		return $this->fb->exec('download.start', array($type, $id));
	}
	public function stop($type, $id){
		return $this->fb->exec('download.stop', array($type, $id));
	}
	public function remove($type, $id){
		return $this->fb->exec('download.remove', array($type, $id));
	}
	
	/* torrent_add(opt) : Paramêtres en entree:
		- url (string): un lien http vers le fichier torrent.
		- magnet (string):  un lien torrent de type magnet link.
		- data (string): lLe contenu du fichier torrent, encodÃ© en base64.
	
	  -liens : https://gist.github.com/1078364
    */
    # FIXME : non fonctionnelle : 'JSON error : [0] : method:download.torrent_add : url, magnet or data required'
	public function torrent_add($url){
		return $this->fb->exec('download.torrent_add', $url);
	}
}

?>
