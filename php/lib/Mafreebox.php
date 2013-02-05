<?php

/* 
 *   author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL 
 * 
 * 
 * Classe de connexion à l'interface d'administration de la Freebox V6 (aussi appelée révolution).
 * - l'interface d'administration est accessible sur votre réseau local à l'adresse : http://mafreebox.fr/
 * - cette interface fonctionne en "WEB2.0", avec des requetes AJAX reproductibles par scripts
 * - c'est l'objet de cette classe.
 * - les échanges (requetes) entre freebox et navigateur Web sont réalisés en JSON, ce qui facilite bien les choses.
 * - cependant, certaines méthodes ne sont pas au format JSON.
 * - il suffit d'observer les échanges avec Firebug pour voir toutes les requetes.
 *
 *
 * basé sur les sources originaux de Monsieur Pierre Quillery (alias dandelionmood) : https://gist.github.com/2579869
 *
 * N'hésitez pas à la surclasser pour définir vos propres méthodes s'appuyant
 * sur celles qui sont présentes ici.
 *
 * Exemple d'utilisation :
 *

<?php

require('lib/Mafreebox.php');
$freebox = new Mafreebox('http://mafreebox.freebox.fr', 'freebox', 'monmdp');

# Listons le contenu du disque dur interne de la Freebox.
$contenu = $freebox->exec( 'fs.list', array('/Disque dur') );

$url = '';
$file = '';
$freebox->download->http_add($file, $url));

# rebooter la freebox
$freebox->system->reboot();

?>

 documentation API : 
 - extra documentation in : MafreeboxDocumentation.php
 - http://www.freebox-v6.fr/wiki/index.php?title=API
 - http://pastebin.com/Xjw2S4St


 This class defines :
	 - __construct($uri, $login, $password)
	 - exec($method, $params),

	 protected methods
	 - login(),
	 - uri($cmd)
 
 */

require_once('lib/CURL.php');

require_once('lib/Conn.php');
require_once('lib/Dhcp.php');
require_once('lib/Download.php');
require_once('lib/Ftp.php');
require_once('lib/Fs.php');
require_once('lib/Phone.php');
require_once('lib/Storage.php');
require_once('lib/System.php');


/* modules list : les modules marqués d'un '*' sont implémentés totalement ou partiellement.

    - Account : account basic http authentication account.unknown
    * Conn : informations et gestion de la connexion Internet,
    * DHCP : Gestion du serveur DHCP,
    * Download : Gestionnaire de téléchargement ftp/http/torrent.
    * Ftp : gestion du serveur FTP,
    - Fs : Systeme de fichiers : Fonctions permettant de lister et de gérer les fichiers du NAS.
    - Fw : Firewall : Fonctions permettant d'interagir avec le firewall.
    - Igd : UPnP IGD : Fonctions permettant de configurer l'UPnP IGD (Internet Gateway Device).
    - IPv6 : Fonctions permettant de configurer IPv6
    - Lan : Fonctions permettant de configurer le réseau LAN.
    - Lcd : Afficheur Fonctions permettant de controler l'afficheur de la Freebox.
    * Phone : Gestion de la ligne téléphonique analogique et de la base DECT.
    - Share : Partage Windows : Fonctions permettant d'interagir avec la fonction de partage Windows de la Freebox.
    - Storage : Systeme de stockage : Gestion du disque dur interne et des disques externe connectés au NAS.
    * System : fonctions système de la Freebox,
    - User : Utilisateurs : Permet de modifier les paramétres utilisateur du boîtier NAS.
    - WiFi : Fonctions permettant de paramétrer le réseau sans-fil.
*/


class Mafreebox {
    private $uri;
    private $login;
    private $password;
    
    private $cookie;

	protected $modules = array();


    /**
     * Constructeur classique
     * @param string $uri : URL de votre freebox
     * @param string $login : Identifiant de connexion (saisir «freebox» par défaut)
     * @param string $password : le mot de passe d'accès à la freebox
     */
    public function __construct($uri, $login, $password) {
        // On assigne les paramètres aux variables d'instance.
        $this->uri      = $uri;
        $this->login    = $login;
        $this->password = $password;
        
        // Connexion automatique puis récupération du cookie.
        $this->cookies = $this->login($this->login, $this->password);

		$this->modules['conn']     = new Conn($this);
		$this->modules['dhcp']     = new Dhcp($this);
		$this->modules['download'] = new Download($this);
		$this->modules['ftp']      = new Ftp($this);
		$this->modules['fs']       = new Fs($this);
		$this->modules['system']   = new System($this);
		$this->modules['phone']    = new Phone($this);
		$this->modules['storage']  = new Storage($this);
    }

    /**
     * Récupération du cookie de session.
     * @return l'identifiant de la session.
     */
    protected function login($login, $password) {

		$curl = new CURL();
		$curl->setopt(CURLOPT_RETURNTRANSFER, 1);
		$curl->setopt(CURLOPT_FOLLOWLOCATION, false);
		# $curl->set_verbose(true);

		$args = array(
            'login'  => $login,
            'passwd' => $password
		);
		$res = $curl->post($this->uri('login.php'), $args);

		if($res->headers()['Status-Code'] != 302)  # 302 Moved Temporarily
			throw new Exception ('connexion error');

		$cookies = array(
			'cookies' => null,
			'csrf'   => null
		);
		
		if(isset($res->headers()['X-FBX-CSRF-Token']))
			$cookies['csrf'] = $res->headers()['X-FBX-CSRF-Token'];

		if(isset($res->headers()['Set-Cookie'])){
			$cookies['cookies'] = $res->headers()['Set-Cookie'];
		}

        #  On retourne les cookies de session.
        return $cookies;
    }

	protected function uri($cmd){
		return  sprintf("%s/%s", $this->uri, $cmd);
		
	}

    /**
     * Interroger l'API de la Freebox.
     * @param string le nom de la méthode à appeler (ex. conn.status)
     * @param array paramètres à passer
     * @return mixed le retour de la méthode appelée.
     */
    public function exec($method, $params = array()) {
        
        // On détermine la page à appeler en fonction du nom de la méthode.
        $url = sprintf("%s%s.cgi", $this->uri, explode('.', $method)[0]);

		$curl = new Curl();
        $curl->set_cookie($this->cookies['cookies']);
		$args = json_encode(array(
            'jsonrpc' => '2.0',
            'method' => $method,
            'params' => $params
		));

		$headers = array(
            'Content-Type: application/json',
			'Accept: application/json, text/javascript, */*',
			"X-FBX-CSRF-Token: {$this->cookies['csrf']}"
		);

		$res = $curl->post($url, $args, $headers);

        // On essaye de décoder le retour JSON.
        $json = json_decode(utf8_encode($res->body), $assoc=true);

        // Gestion minimale des erreurs.
        if ($json === false)
            throw new Exception("Erreur dans le retour JSON !");
        
        if (isset($json['error'])){
            throw new Exception(sprintf('JSON error : [%d] : method:%s : %s', 
				$json['error']['code'],
				$json['error']['method'],
				$json['error']['message']
			));
        }
        // Ce qui nous intéresse est dans l'index «result»
        return $json['result'];
    }

    /**
     * recupérer un fichier, ou plus généralement une adresse (uri) sur la freebox (hors fichiers du disque dur)
     */
    public function uri_get($path) {
		$curl = new Curl();
        $curl->set_cookie($this->cookies['cookies']);

		$headers = array(
			'Accept: */*',
			"X-FBX-CSRF-Token: {$this->cookies['csrf']}"
		);
		$url = $this->uri($path);
		print_r("url = $url\n");
		$res = $curl->get($url, $args=array(), $headers);
		return $res->body();

	}

	public function debug(){
		# ...
	}
	
	# allow magic acces : $freebox->module->method()
	public function __get($name){
		if(array_key_exists($name, $this->modules))
			return $this->modules[$name];
		else
			throw new Exception ("module $name does't exists");
	}
}
/* Subclasses with all JSON services.

Account : account basic http authentication
    account.unknown

Fs : Systeme de fichiers : Fonctions permettant de lister et de gérer les fichiers du NAS.
    fs.list
    fs.get
    fs.operation_progress
    fs.operation_list
    fs.abort
    fs.set_password
    fs.move
    fs.copy
    fs.remove
    fs.unpack
    fs.mkdir

Fw : Firewall : Fonctions permettant d'interagir avec le firewall.
    fw.wan_redirs_get
    fw.wan_range_redirs_get
    fw.wan_redir_del
    fw.wan_range_redir_del
    fw.wan_redir_add
    fw.wan_range_redir_add
    fw.dmz_get
    fw.dmz_set
    fw.lfilter_config_get
    fw.lfilter_config_set
    fw.lfilters_get
    fw.lfilter_add
    fw.lfilter_del

Igd : UPnP IGD : Fonctions permettant de configurer l'UPnP IGD (Internet Gateway Device).
    igd.config_get
    igd.config_set
    igd.redirs_get
    igd.redir_del

IPv6 : Fonctions permettant de configurer IPv6
    ipv6.config_get
    ipv6.config_set

Lan : Fonctions permettant de configurer le réseau LAN.
    lan.ip_address_get
    lan.ip_address_set

Lcd : Afficheur Fonctions permettant de controler l'afficheur de la Freebox.
    lcd.brightness_get
    lcd.brightness_set


Share : Partage Windows : Fonctions permettant d'interagir avec la fonction de partage windows de la freebox.
    share.get_config
    share.set_config

Storage : Systeme de stockage : Gestion du disque dur interne et des disques externe connectÃ©s au NAS.
    storage.list
    storage.disk_get
    storage.disk_format_internal
    storage.disk_disable
    storage.mount
    storage.umount
    storage.disable

User : Utilisateurs : Permet de modifier les paramÃ¨tres utilisateur du boÃ®tier NAS.
    user.password_reset
    user.password_set
    user.password_check_quality

WiFi : Fonctions permettant de paramÃ©trer le rÃ©seau sans-fil.
    wifi.status_get
    wifi.config_get
    wifi.ap_params_set
    wifi.bss_params_set
    wifi.mac_filter_add
    wifi.mac_filter_del
    wifi.stations_get

*/

?>
