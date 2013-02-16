#!/usr/bin/ruby

# coding: UTF-8

=begin

author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL

Classe de connexion à l'interface d'administration de la Freebox V6 (aussi appelée révolution).
 - l'interface d'administration est accessible sur votre réseau local à l'adresse : http://mafreebox.freebox.fr/
 - cette interface fonctionne en "WEB2.0", avec des requetes AJAX reproductibles par scripts
 - c'est l'objet de cette classe.
 - les échanges (requetes) entre freebox et navigateur Web sont réalisés en JSON, ce qui facilite bien les choses.
 - cependant, certaines méthodes ne sont pas au format JSON.
 - il suffit d'observer les échanges avec Firebug pour voir toutes les requetes.

N'hésitez pas à la surclasser pour définir vos propres méthodes s'appuyant
sur celles qui sont présentes ici.


Dépendances :
 - json
 - net/http

 - sur debian-like : apt-get install ruby1.9.1 ruby-httpclient ruby-json


Exemple d'utilisation :

	require './Mafreebox.rb'

	cnf=ENV['HOME'] + '/.config/mafreebox.yml'

	if(File.exist?(cnf))
		config = YAML::load(File.open(cnf))

		# vous pouvez creer un fichier $HOME/.config/mafreebox.yml avec le contenu suivant :
		# :url: http://mafreebox.freebox.fr/ (ou adresse IP externe)
		# :login: freebox
		# :passwd: votre-mot-de-passe

	else
		config = YAML::load(YAML::dump(
			:url		=> 'http://mafreebox.freebox.fr/', # ou votre adresse IP externe
			:login		=> 'freebox',
			:passwd		=> 'your-password'
		))

	end

	begin
		mafreebox = Mafreebox::Mafreebox.new(config)
		# throws an exception on login or connexion error
		mafreebox.login
	rescue
		puts "connexion error :"
		puts "- url : " + config[:url]
		puts "- login : " + config[:login]
		puts "- passwd : " + config[:passwd]
		exit(-1)
	end

	# execution d'une requete JSON concernant le module FS
	p mafreebox.exec('fs.list', ['Disque dur/']);

	# exemple d'utilisation du module "Unix".
	mafreebox.unix.cp('/Disque dur/test/toto.txt','/Disque dur/test/titi.txt')
	mafreebox.unix.rm('/Disque dur/test/titi.txt')
	mafreebox.unix.get('/Disque dur/test/toto.txt')

	# Reboot de la Freebox ; rien de plus simple.
	p mafreebox.system.reboot

=end

module Mafreebox

require 'net/http'
require 'json'
require 'yaml'

=begin

class tree :
	module Mafreebox
		Core
			Mafreefox
		Module
			[Conn, Download, Igd, IPv6, Lan, Lcd, Phone, Share, System, User]
			Fs
				Unix


class composition (délégation)
	Module -> Mafreebox (chaque sous-classe de Module embarque une référence)

=end

# support des fonctions de base (Core)
# - gestion des modules, 
# - gestion des requêtes sur protocole HTTP
class Core

    def initialize config
		@modules = Hash.new

		@modules[:conn]     = Conn.new(self)
		@modules[:download] = Download.new(self)
		@modules[:fs]       = Fs.new(self)
		@modules[:igd]      = Igd.new(self)
		@modules[:ipv6]     = IPv6.new(self)
		@modules[:lan]      = Lan.new(self)
		@modules[:lcd]      = Lcd.new(self)
		@modules[:phone]    = Phone.new(self)
		@modules[:share]    = Share.new(self)
		@modules[:system]   = System.new(self)
		@modules[:unix]     = Unix.new(self)
		@modules[:user]     = User.new(self)

		# @modules[:dhcp]   = Dhcp.new(self)
		# @modules[:ftp]    = Ftp.new(self)
		# @modules[:fw]     = Fw.new(self)
		# @modules[:storage]= Storage.new(self)
		# @modules[:wifi]   = Wifi.new(self)

    end

	def post(cmd, args, headers={})

		uri = self.uri(cmd)

		headers['Cookie']           = @config[:cookie] if(@config[:cookie] != nil)
		headers['x-fbx-csrf-token'] = @config[:token]  if(@config[:token]  != nil)

		request = Net::HTTP::Post.new(uri.to_s)

		# set headers into request
		headers.each{ |h|
			request[h[0]] = h[1]
		}

		# args can be an Hash or a String
		if args.is_a? Hash
			request.set_form_data(args)
		else
			request.body = args
		end

		http = Net::HTTP.new(uri.host, uri.port)
		# http.set_debug_output $stdout #useful to see the raw messages going over the wire
		http.read_timeout = 15
		http.open_timeout = 15

		http.request(request)
	end

	def json_exec(cmd, args)
		self.exec(cmd, args)
	end

	def exec(cmd, args=[])
		args = {
			'jsonrpc' => '2.0',
            'method'  => cmd,
            'params'  => args
		}

		headers={
			'content-type'		=> 'application/json'
		}

		cgi = cmd.split('.')[0] + '.cgi'
		JSON::parse(self.post(cgi, args.to_json, headers).body)['result']
	end

	# automatic call of modules :
	# - si sym (nom de la méthode appellée fait partie de la liste de modules, on retourne une référence
	# sinon, on laisse passer (super) : ce qui va générer une exception
	def method_missing(sym, *args)		
		return @modules[sym] if(@modules.has_key?(sym))
		super
	end

	# retourne un objet URI avec l'URL du service (http://mafreebox) + la commande à exécuter
	def uri(cmd)
		URI.parse(@config[:url] + cmd)
	end

end

class Mafreebox < Core

    def initialize(config)
		super

		@config = config
		
		# les variables de sessions seront embarquées dans la structure de configuration (@config)
		@config[:cookie] = nil
		@config[:token] = nil
    end

	# login sur l'interface Mafreebox
	# - si l'authentification échoue, une exception est générée.
	# - en cas de succès, la valeur true est retournée (pas très utile)
	# - le succès de l'authentification est marqué par la redirection (code 302) vers une nouvelle page
	# - les parametres de session (cookie, ...) sont enregistrés dans la configuration.
	def login
		args = {
			'login'  => @config[:login],
			'passwd' => @config[:passwd]
		}

		response = self.post('login.php', args)

		# si la réponse n'est pas une redirection (code 302), il s'agit vraissemblament d'une erreur de d'authentification.
		if(response.code != '302')
			raise "erreur de connexion"
		end

		# ouf, tout va bien ; on enregistre les variables de session (cookies) ; servira par la suite pour les requêtes JSON.
		@config[:cookie] = response['Set-Cookie']
		@config[:token] = response['x-fbx-csrf-token']

		return true
	end
end

# fonctions communes à tous les modules
class Module
	@fb
	@name
	
	# c'est la classe Freebox (fb) qui permettra par délégation d'adresser les requetes HTTP.
	def initialize fb
        @fb = fb
        @name = nil
	end
	
	# exec permet de faire une requete JSON avec le nom du module passé dans la requête.
	# ex: system.exec('reboot') -> JSON : @fb('system.reboot')
	#
	def exec(cmd, args=[])
		raise("error : no module name for " + self.class.to_s) if @name==nil
		cmd = sprintf("%s.%s", @name, cmd)
		@fb.exec(cmd, args)
	end

	# un POST par délégation sur la classe Freebox.
	def post(cmd, args)
		@fb.post(cmd, args)
	end
end

=begin

modules list :

  - les modules marqués d'un '*' sont implémentés totalement ou partiellement.
  - les modules marqués d'un '-' ne sont pas implémentés.

	- Account : account basic http authentication : rien de précis sur ce module dans l'API JSON ...
	* Conn : informations et gestion de la connexion Internet,
	- DHCP : Gestion du serveur DHCP,
	* Download : Gestionnaire de téléchargement ftp/http/torrent.
	- Ftp : gestion du serveur FTP,
	* Fs : Systeme de fichiers : Fonctions permettant de lister et de gérer les fichiers du NAS.
	- Fw : Firewall : Fonctions permettant d'interagir avec le firewall.
	* Igd : UPnP IGD : Fonctions permettant de configurer l'UPnP IGD (Internet Gateway Device).
	* IPv6 : Fonctions permettant de configurer IPv6
	* Lan : Fonctions permettant de configurer le réseau LAN.
	* Lcd : Afficheur Fonctions permettant de controler l'afficheur de la Freebox.
	* Phone : Gestion de la ligne téléphonique analogique et de la base DECT.
	* Share : Partage Windows : Fonctions permettant d'interagir avec la fonction de partage Windows de la Freebox.
	- Storage : Systeme de stockage : Gestion du disque dur interne et des disques externe connectés au NAS.
	* System : fonctions système de la Freebox,
	* User : Utilisateurs : Permet de modifier les paramétres utilisateur du boîtier NAS.
	- WiFi : Fonctions permettant de paramétrer le réseau sans-fil.


 System : 
 
 - system.uptime_get() : retourne le temps écoulé depuis la mise en route de la freebox (en secondes)
 - system.mac_address_get() : adresse MAC de la FB
 - system.serial_get() : n° de série de la FB
 - system.reboot ([timeout]) : Redémarre la freebox (timeout = temps d'attente en secondes)
 - system.fw_release_get() : renvoie la version courante du firmware
 
 - non documentées :
 - system.rotation_set(): 
 
 a faire : récupérer les températures depuis code HTML, page "/settings.php?page=misc_system"
 
       <li>Température CPUm : <span style="color: black;">XX °C</span></li>
       <li>Température CPUb : <span style="color: black;">XX °C</span></li>
       <li>Température SW : <span style="color: black;">XX °C</span></li>
       <li>Vitesse ventilateur : <span>XXXX RPM</span></li>

=end

class System < Module

	def initialize fb
        super
        @name = 'system'
	end

	def get_all
		return {
			'uptime'     => self.uptime_get,
			'serial'     => self.serial_get,
			'mac'        => self.mac_address_get,
			'fw-release' => self.fw_release_get,
		}
	end

	def uptime_get
		self.exec('uptime_get')
	end

	def mac_address_get
		self.exec('mac_address_get')
	end

	def serial_get
		self.exec('serial_get')
	end

	def reboot(timeout)
		self.exec('reboot', [timeout])
	end

	def fw_release_get
		self.exec('fw_release_get')
	end
end

=begin 

 Fs : Fonctions permettant de lister et de gérer les fichiers du NAS.
 
 méthodes JSON :
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
 
 correspondance méthodes :
 
 - get() -> POST /get.php {filename=....},
 - get_json -> JSON : fs.get

=end

class Fs < Module
	def initialize fb
        super
        @name = 'fs'
	end

	def list(path)
		self.exec('list', [path])
	end

	def json_get(file, opts=nil)
		if(opts == nil)
			self.exec('get', file)
		else
			self.exec('get', [file, opts])
		end
	end

	def get(path)
		args= {
			'filename' => path
		}
		self.post('get.php', args).body
	end

	def copy(src, dest)
		self.exec('copy', [src, dest])
	end

	def mkdir(path)
		self.exec('mkdir', path)
	end

	def remove(path)
		self.exec('remove', path)
	end

	def move(src, dest)
		self.exec('move', [src, dest])
	end
end

# Unix : permet de disposer de fonction de manipulation de fichiers à la Unix.
class Unix < Fs

	alias ls list
	alias mv move
	alias cp copy
	alias rm remove
	alias rmdir remove

end


=begin

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

=end

class Download < Module

	def initialize fb
        super
        @name = 'download'
	end

	def list()
		self.exec('list')
	end

	def config_get()
		self.exec('config_get')
	end

	def config_set(config)
		self.exec('config_set', config)
	end

	def http_add(name, url)
		self.exec('http_add', [name, url])
	end

end

=begin

Conn: informations concernant l'état de la connexion Internet et réponse au ping.

types:

	conn-status:
	- type: rfc2684
	- state: up|down
	- media: adsl|fibre?
	- ip_address: ip externe

	- rate_down: int (débit download instantané)
	- rate_up: int (débit upload instantané)

	- bytes_down: volume téléchargé (download) depuis reboot en octet
	- bytes_up: volume téléchargé (upload) depuis reboot en octet

	- bandwidth_up: bande passante en octets/s (upload)
	- bandwidth_down: bande passante en octets/s (download)


	log-type:
	- [id] => int
	- [type] => up
	- [date] => time_t 
	- [connection] => dgp_priv|dgp_pub : état de la connexion (publique ou privée) 


methods :

	conn.status -> conn-status : état de la connexion Internet (débit instantané, bande passante, volumétrie, état).
	conn.wan_ping_get : état de la réponse au ping sur l'adresse IP externe
	conn.wan_ping_set(bool) : configuration de la réponse au ping
	conn.remote_access_set(bool) : autorise l'accès à l'interface d'administration à distance (et le scripting),
	conn.remote_access_get : configuration
	conn.proxy_wol_get : état du proxy wakeup on lan (WOL)
	conn.proxy_wol_set(bool) : configuration du proxy WOL
	conn.logs : array(log-type) : historique de la connexion Internet : retrace les connexions et déconnexion.
	conn.logs_flush : efface l'historique des connexions
	conn.wan_adblock_get : état du blocage de la publicité
	conn.wan_adblock_set(bool) : blocage de la publicité

=end

class Conn < Module

	def initialize fb
        super
        @name = 'conn'
	end

	def get_all
		return {
			:status        => self.status,
			:ping          => self.wan_ping_get,
			:remote_access => self.remote_access_get,
			:logs          => self.logs,
		}
	end

	alias get get_all
	
	def status
		self.exec('status')
	end
	
	def logs
		self.exec('logs')
	end
	
	def logs_flush
		self.exec('logs_flush')
	end
	
	def wan_ping_get
		self.exec('wan_ping_get')
	end
	
	def wan_ping_set(bool)
		self.exec('wan_ping_set', bool)
	end

	def remote_access_get
		self.exec('remote_access_get')
	end
	
	def remote_access_set(bool)
		self.exec('remote_access_set', bool)
	end

	def wan_adblock_get
		self.exec('wan_adblock_get')
	end
	
	def wan_ping_set(bool)
		self.exec('wan_adblock_set', bool)
	end
end


=begin

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

=end

class Phone < Module

	def initialize fb
        super
        @name = 'phone'
	end

	def status
		self.exec('status')
	end

	alias get status
	
	def fxs_ring(bool)
		self.exec('fxs_ring', bool)
	end

	alias ring fxs_ring

	def dect_paging(bool)
		self.exec('dect_paging', bool)
	end

	def dect_registration_set(bool)
		self.exec('dect_registration_set', bool)
	end

	def dect_params_set(bool)
		self.exec('dect_params_set', bool)
	end

	def dect_delete(id)
		self.exec('dect_delete', id)
	end

end

=begin

IPv6 : Fonctions permettant de configurer IPv6

methods :
    ipv6.config_get():ipv6-cnf
    ipv6.config_set(ipv6-cnf)

types:

	ipv6-cnf:
	- enabled : bool (true, false)

=end

class IPv6 < Module

	def initialize fb
        super
        @name = 'ipv6'
	end

	def config_get
		self.exec('config_get')
	end

	def config_set(cnf)
		self.exec('config_set', cnf)
	end

	alias get config_get
	alias set config_set

end


=begin

Igd : UPnP IGD : Fonctions permettant de configurer l'UPnP IGD (Internet Gateway Device).
 
methods :
    igd.config_get():igd-cnf :  Retourne la configuration courante. 
    igd.config_set(igd-cnf) :  Applique la configuration. 
    igd.redirs_get() :  Liste les redirections de ports créees par UPnP 
    igd.redir_del(ext_src_ip, ext_port, proto) :  Supprime une redirection. 

types:

	igd-cnf:
	- enabled: boolean

=end

class Igd < Module

	def initialize fb
        super
        @name = 'igd'
	end

	def get_all
		return {
			:config => self.config_get,
			:redirs => self.redirs_get,
		}
	end

	alias get get_all

	def config_get
		self.exec('config_get')
	end

	def config_set(cnf)
		self.exec('config_set', cnf)
	end

	def redirs_get
		self.exec('redirs_get')
	end

	def redir_del(ext_src_ip, ext_port, proto)
		self.exec('redir_del', [ext_src_ip, ext_port, proto])
	end


end

=begin


Lcd : Afficheur Fonctions permettant de controler l'afficheur de la Freebox.

methods :

    lcd.brightness_get():int (pourcentage)
    lcd.brightness_set(value:int)

=end

class Lcd < Module

	def initialize fb
        super
        @name = 'lcd'
	end

	def brightness_get
		self.exec('brightness_get')
	end

	def brightness_set(percent)
		self.exec('brightness_set', percent)
	end

	# fait clingoter l'afficheur LCD :
	# - count : nombre d'occurrences du clignotement,
	# - delay : temps en mili-secondes du cyle. 
	# - le cycle est coupé en 3 intervalles égaux,
	# - l'afficheur est en luminosité basse 1/3 du temps et en luminosité forte 2/3 du temps.
	def blink(count=60, delay=500.0, ratio=2)
		# l'état initial est concervé afin de remettre en fin de procédure.
		state = self.get
		delay = delay / 1000 / 3
		i=count
		while (i>0)
			self.set(0)
			sleep(delay)
			self.set(100)
			sleep(delay*2)
			i -= 1			
		end
		self.set(state)
	end

	alias get brightness_get
	alias set brightness_set

end


=begin

Share : Partage Windows : Fonctions permettant d'interagir avec la fonction de partage windows de la freebox.

methods :

    share.get_config:type-share-cnf
    share.set_config(type-share-cnf)

types :

	type-share-cnf:
	- [workgroup] => string ; défaut=freebox
	- [logon_password] => 
	- [print_share_enabled] => 1
	- [file_share_enabled] => 1
	- [logon_enabled] => 
	- [logon_user] => string ; defaut=freebox

=end

class Share < Module

	def initialize fb
        super
        @name = 'share'
	end

	def get_config
		self.exec('get_config')
	end

	def set_config(cnf)
		self.exec('set_config', cnf)
	end

	alias get get_config
	alias set set_config

end

=begin

User : Utilisateurs : Permet de modifier les paramêtres utilisateur du boitier NAS.

methods:

    user.password_reset(login) : Réinitialize le mot de passe d'un utilisateur. 
    user.password_set(login, oldpass, newpass) : Change le mot de passe d'un utilisateur. 
    user.password_check_quality(passwd) : 

=end

class User < Module

	def initialize fb
        super
        @name = 'user'
	end

	def password_reset(login)
		self.exec('password_reset', login)
	end

	def password_set(login, oldpass, newpass)
		self.exec('password_set', login, oldpass, newpass)
	end

	def password_check_quality(passwd)
		self.exec('password_check_quality', passwd)
	end

end

=begin

Lan : Fonctions permettant de configurer le réseau LAN.

methods :

    lan.ip_address_get
    lan.ip_address_set

=end

class Lan < Module

	def initialize fb
        super
        @name = 'lan'
	end

	def ip_address_get
		self.exec('ip_address_get')
	end

	def ip_address_set(ip)
		self.exec('ip_address_set', ip)
	end

	alias get ip_address_get
	alias set ip_address_set

end

end # module Mafreebox
