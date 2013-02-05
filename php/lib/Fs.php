<?php

/* author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 

Fs : Fonctions permettant de lister et de gérer les fichiers du NAS.

- fs.list(dir, opt) : liste les fichiers d'un répertoire donné. 
- fs.get(file [, opt]) : récupère les données d'un fichier sur le disque. 
- fs.operation_progress(id) : récupère l'état d'une tâche asynchrone en cours. 
- fs.operation_list() : Récupère la liste de toutes les opérations asynchrones en cours. 
- fs.abort(id) : tue une tâche en cours, 
- fs.set_password(id, password) : fourni un mot de passe à l'opération asynchrone le requérant. La tâche doit être dans l'état 'waiting_password'. 
- fs.move(from, to): déplace un ou des fichiers vers un nouveau répertoire. 
- fs.copy(from, to): copie un ou des fichiers vers un nouveau répertoire. 
- fs.remove(path): supprime définitivement un ou des fichiers. 
- fs.unpack(archive [, destination]): Décompresse une archive dans le répertoire. Si le répertoire de destination n'est pas renseigné, décompresse dans le répertoire ou se trouve l'archive. 
- fs.mkdir(path): Crée un répertoire sous /media étant donné son chemin 

*/

class Fs {
	protected $fb;
	public function __construct($fb){
		$this->fb = $fb;
	}

	/*
		liste les fichiers du répertoire $dir

		Paramètres en entrée:
			- dir:string : Chemin d'accès vers le répertoire à lister (ex: "/Jeux")
			- opt:string : Options:
			  - with_partition: si 'dir' est '/', donne des informations supplémentaires sur les points de montage.
			  - with_attr: récupère les attributs du fichier (type). L'appel peut être moins rapide.

		à la lecture du code explorer.js, et des tests :
		- l'option with_partition n'est plus gérée,
		- l'option with_attr est présente par défaut.


		valeur de retour : une liste d'entrée de cette forme (les attributs marqué d'un '*' sont retournés si with_attr=>true:

            [mimetype] => inode/directory ou type mime ( text/plain, application/x-compressed-tar, ...)
            [name] => nom
            [type] => dir|file
            * [size] => int
            * [modification] => time_t

	*/

	public function _list($dir, $opt=null){
		if($opt == null)
			return $this->fb->exec('fs.list', $dir);
		else
			return $this->fb->exec('fs.list', array($dir, $opt));
	}

	/*

		fs.get (file [, opt])

		Récupère les données d'un fichier sur le disque.

		Cette méthode, accessible en jsonrpc, n'est pas très efficace car le contenu du fichier a besoin d'être lu pour être encodé en UTF-8. 
		Cela peut aussi se révéler problématique pour les fichiers binaires. La taille maximale est limitée à 4Mo.

		Une autre méthode, sans limitation, disponible en GET, est préférable. eg: wget 'http://mafreebox.freebox.fr/fs.cgi?file=/Disque dur/gros.img'
		Paramètres en entrée:

			$file:string :	Nom d'accès absolu du fichier.

			$opt:string (Optionnel) 
			- base64 	Obtenir le contenu du fichier encodé en base64.

		Retour:
			Une chaîne de caractèresde chaîne de caractères, Le contenu du fichier.

	*/

	public function get_json($file, $opts=null){
		if($opts == null)
			return $this->fb->exec('fs.get', $file);
		else
			return $this->fb->exec('fs.get', array($file, $opts));
	}


	public function get($file){

		# http://mafreebox.fr/get.php avec le paramètre POST « filename=/Disque dur/chemin/vers/le/fichier ». 
		$args = array(
		  'filename' =>  $file,
		);

		$res = $this->fb->post('/get.php', $args, $refer='/explorer.php');
		return $res->body(); 
	}


	/*
		fs.operation_progress (id)

		Récupère l'état d'une tâche asynchrone en cours.

		Paramètres en entrée:

			id:int : Identifiant de l'opération.

		Retour:
			Un objet de type async_task_status.
	*/
	public function operation_progress(){
		return $this->fb->exec('fs.operation_progress', $id);
	}

	/*
		fs.operation_list ()

		Récupère la liste de toutes les opérations asynchrones en cours.

		Retour:
			Un tableau d'objets de type async_task_status.
	*/

	public function operation_list(){
		return $this->fb->exec('fs.operation_list');
	}

}
?>
