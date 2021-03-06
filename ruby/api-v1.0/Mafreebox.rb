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
 - nokogiri,
 - yaml
 
 - sur debian-like : apt-get install ruby1.9.1 ruby-httpclient ruby-json ruby-nokogiri


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

begin
	require 'net/http'
	require 'json'
	require 'yaml'
	require 'nokogiri'  # http://ruby.bastardsbook.com/chapters/html-parsing/ ; http://nokogiri.org/tutorials
rescue ScriptError
	puts "Cette application a besoin des librairies suivantes pour fonctionner :
 - net/http
 - json,
 - yaml,
 - nokogiri
elles sont disponibles soit dans les depots de votre distribution (apt-cache search <nom-librairie>) ou dans les dépots Ruby via la commande gem.
Sur debian et ubuntu : 
	sudo apt-get install ruby1.9.1 ruby-nokogiri ruby-json ruby-httpclient (wheezy)
	sudo apt-get install ruby1.9.1 libnokogiri-ruby ruby-json libhttpclient-ruby1.9.1 (sqeeze)

"
	exit(-1)
end


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
		@modules[:wifi]     = Wifi.new(self)

		# @modules[:dhcp]   = Dhcp.new(self)
		# @modules[:ftp]    = Ftp.new(self)
		# @modules[:fw]     = Fw.new(self)
		# @modules[:storage]= Storage.new(self)

		@modules[:extra]     = Extra.new(self)
		@modules[:rrd]       = Rrd.new(self)

    end

	def http_post(cmd, args, headers={})

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
		http.set_debug_output $stdout #useful to see the raw messages going over the wire
		http.read_timeout = 15
		http.open_timeout = 15

		http.request(request)
	end

	def http_get(cmd, headers={})

		uri = self.uri(cmd)

		headers['Cookie']           = @config[:cookie] if(@config[:cookie] != nil)
		headers['x-fbx-csrf-token'] = @config[:token]  if(@config[:token]  != nil)

		request = Net::HTTP::Get.new(uri.to_s)

		# set headers into request
		headers.each{ |h|
			request[h[0]] = h[1]
		}

		http = Net::HTTP.new(uri.host, uri.port)
		# http.set_debug_output $stdout #useful to see the raw messages going over the wire
		http.read_timeout = 15
		http.open_timeout = 15

		http.request(request)
	end
	
	alias post http_post
	alias get http_get

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

	def exec_xml(cmd, args=[])
		args['csrf_token'] =  self.token

		headers = {
			'X-Requested-With' => 'XMLHttpRequest',
		}

		return self.post('wifi.cgi', args, headers)
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


	def export_csv(rows, header=[])
		require 'csv'

		out = CSV.generate do |csv|
	  
			if rows[0].is_a? Hash 
				if header.length == 0
					csv << rows[0].keys
				else
					csv << header 
				end
				rows.each do |rec|
						csv << rec.values
				end
			else
				csv << header if not header.length==0
				rows.map {|row| csv << row}
			end
		end
		return out
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
	
	def token
		return @config[:token]
	end
	
	def cookie
		@config[:cookie]
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

	def exec_xml(cmd, args=[])
		@fb.exec_xml(cmd, args)
	end

	# un POST par délégation sur la classe Freebox.
	def post(cmd, args, headers)
		@fb.post(cmd, args, headers)
	end

	def http_get(cmd)
		@fb.http_get(cmd)
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
	* WiFi : Fonctions permettant de paramétrer le réseau sans-fil.

 System : 
 
 - system.uptime_get() : retourne le temps écoulé depuis la mise en route de la freebox (en secondes)
 - system.mac_address_get() : adresse MAC de la FB
 - system.serial_get() : n° de série de la FB
 - system.reboot ([timeout]) : Redémarre la freebox (timeout = temps d'attente en secondes)
 - system.fw_release_get() : renvoie la version courante du firmware
 
 - non documentées :
 - system.rotation_set(): 
 
 a faire :

=end

class System < Module

	def initialize fb
        super
        @name = 'system'
	end

	def get_all
		return {
			:uptime     => self.uptime_get,
			:serial     => self.serial_get,
			:mac        => self.mac_address_get,
			:fwrelease  => self.fw_release_get,
			:infos      => self.infos,
		}
	end
	alias get get_all

	def uptime_get
		self.exec('uptime_get')
	end

	def mac_address_get
		self.exec('mac_address_get')
	end

	def serial_get
		self.exec('serial_get')
	end

	def reboot(timeout=3)
		self.exec('reboot', [timeout])
	end

	def fw_release_get
		self.exec('fw_release_get')
	end

=begin
	 récupérer les températures depuis code HTML, page "/settings.php?page=misc_system"
 
       <li>Température CPUm : <span style="color: black;">XX °C</span></li>
       <li>Température CPUb : <span style="color: black;">XX °C</span></li>
       <li>Température SW : <span style="color: black;">XX °C</span></li>
       <li>Vitesse ventilateur : <span>XXXX RPM</span></li>
=end

	def infos
		body = self.http_get('settings.php?page=misc_system').body
		page = Nokogiri::HTML(body)
		
		infos = {}

		# xpath : /html/body/div[4]/div[3]/div.bloc/ul/li/span | html body div#fluid div#col_1.setting_block div.bloc ul li span
		page.css('html body div#fluid div#col_1.setting_block div.bloc ul li').each{ |li|

			if(m = li.inner_text.match(/Temp.*rature (.+?) : (\d+)/))
				infos[m[1]] = m[2]
			elsif(m = li.inner_text.match(/Vitesse ventilateur : (\d+) RPM/))
				infos['ventilateur'] = m[1]
			end
		}
		
		return infos
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
	- ftp 	Téléchargement d'un lien ftp.

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

	alias get config_get
	alias set config_set

	def http_add(name, url)
		self.exec('http_add', [name, url])
	end

	def start(type, id)
		self.exec('start',[type, id])
	end

	def stop(type, id)
		self.exec('stop',[type, id])
	end

	def get(type, id)
		self.exec('get',[type, id])
	end

	def remove(type, id)
		self.exec('remove',[type, id])
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

	def wan_adblock_set(bool)
		self.exec('wan_adblock_set', bool)
	end
end


=begin

Phone : Téléphonie : Contrôle de la ligne téléphonique analogique et de la base DECT.

todo : 
- exploiter le journal des appels au format HTML et l'exporter dans un format utilisable (xml, csv, ...) / fait pour php.

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
	- enabled => bool
	- nemo_mode => 
	- ring_on_off => bool
	- eco_mode => 
	- pin => 1234 (code pin)
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

	def logs
	
		# on récupère la listes des appels passés et recus, au format HTML
		body = self.http_get('/settings.php?page=phone_calls').body
		
		# le parser Nokogiri permettra de réaliser les extractions
		# après sélection des sections HTML (méthode css)
		page = Nokogiri::HTML(body)
		
		# liste des éléments retournés
		list = {
			:recus => [],  # liste des appels reçus
			:passes => []  # liste des appels passés
			}

		# appels recus
		page.css('//table[1].bloc/tr').each{ |li|
			e = li.css('td')

			list[:recus] << {
				:heure => e[0].inner_text,  # heure d'appel : format Mardi 5 février à 15:29:40
				:date  => self.date_parse(e[0].inner_text),  # date + heure décodé
				:nom   => e[1].inner_text,  # nom ou numéro 
				:tel   => e[2].inner_text,  # numéro de l'appelant
				:duree => self.parse_duration(e[3].inner_text)  # duré de l'appel ou "appel manqué"
			}
		}

		# appels passés
		page.css('//table[2].bloc/tr').each{ |li|
			e = li.css('td')

			list[:passes] << {
				:heure => e[0].inner_text,  # heure d'appel : format Mardi 5 février à 15:29:40
				:nom   => e[1].inner_text,  # nom ou numéro 
				:tel   => e[2].inner_text,  # numéro de l'appelant
				:duree => e[3].inner_text,  # duré de l'appel ou "appel manqué"
			}
		}

		return list
	end

	# permet de décoder la chaine "durée de l'appel" codée en Francais  self.logs[][:heure]
	# retourne un hash contenant : 
	# - :fr => l'heure initiale (francais)
	# - :en => l'heure décodée en anglais
	# - :time_t : l'heure au format time_t (nb seconde écoulées depuis une date de référence =~ 1/01/1970).
	# - :date : un objet de type DateTime.
	def date_parse(date)

		require 'time'
		# suppress characters accents (à->a, è->e) and lowercase
		date = date.downcase
		# date = date.to_ascii.downcase

		week_days = %w(lundi mardi mercredi jeudi vendredi samedi dimanche)
		months    = %w(janvier février mars avril mai juin juillet aout septembre octobre novembre décembre)
		year = Date.today.year
	
		# expr : /(week-name) (day-number) (month) (time)/
		expr = /(#{week_days.join('|')})\s+(\d+)\s+(#{months.join('|')})\s+[aà]\s+(.*)/i
		e = date.scan(expr)
	
		raise("parse error : unsupported date format or format error : '#{date}'") if(e.length == 0)
		e = e[0]

		d = DateTime.parse(sprintf("%.4d/%.2d/%.2s %s UTC+1", Date.today.year, months.index(e[2])+1, e[1], e[3]))
		
		return {
			:fr       => date,
			:en       => Time.parse(d.to_s).to_s,
			:time_t   => d.to_time.to_i,
			:date     => d
		}

	end

	# parse duration string in the form in french :
	# 00:01:01 -> 1 minute 1 seconde
	# 00:00:22 -> 22 secondes
	# 00:00:00 -> appel manqué
	# 
	def parse_duration duration

		return 0 if duration == "appel manqué"

		h,m,s=0,0,0

		h = match(duration, /(\d+)\s+heures*/)
		m = match(duration, /(\d+)\s+minutes*/)
		s = match(duration, /(\d+)\s+secondes*/)
		
		return h*3600+m*60+s
	end

	def match str, expr
		m = str.scan(expr)
		return 0 if m.size==0
		return m[0][0].to_i
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

methods extra (hors API native):
	Ldc:blink(count, delay) : fait clignoter l'afficheur LCD
	Ldc:blink_code(id, count, delay) : fait clignoter l'afficheur LCD par séquence de façon à identifier un code d'erreur

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

	# fait clignoter l'afficheur LCD :
	# - count : nombre d'occurrences du clignotement,
	# - delay : temps en mili-secondes du cyle. 
	# - le cycle est coupé en 3 intervalles égaux,
	# - l'afficheur est en luminosité basse 1/3 du temps et en luminosité forte 2/3 du temps.
	def blink(count=60, delay=500)
		# l'état initial est conservé afin de remettre en fin de procédure.
		state = self.get
		delay = 1.0 * delay / 1000 / 3
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

	# fait clignoter l'afficheur LCD par séquence de façon à identifier un code d'erreur
	# id = code d'erreur = nombre de clignotement,
	# repeat : combien de fois on répète le clignement
	# delay : vitesse de clognement.
	def blink_code(id, repeat=30, delay=500)
		state = self.get
		delay = delay * 1.0 / 1000 / 2
		self.set(0)
		sleep(2)
		(1..repeat).each{ |r|
			(1..id).each { |i|
				self.set(100)
				sleep(delay)
				self.set(0)
				sleep(delay)
			}
			sleep(2)
		}
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
	
	# tous les autres modules disposent de config_[set|get].
	alias config_get get_config
	alias config_set set_config

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


=begin

WiFi : Fonctions permettant de paramétrer le réseau sans-fil.
    wifi.status_get() : Retourne l'état du réseau sans fil 
    wifi.config_get() : Retourne la configuration du réseau sans fil
    wifi.ap_params_set(params) : Modifie la configuration de la carte Wifi 
    wifi.bss_params_set(bss_cfg_name, params) : 
    wifi.mac_filter_add(bss_cfg_name, filter_type, mac, comment): Ajoute une entrée à  la liste des MACs autorisées/interdites 
    wifi.mac_filter_del(bss_cfg_name, filter_type, mac) :  Supprime une entrée de la liste des MACs autorisées/interdites 
    wifi.stations_get(bssid, enabled) : Retourne la liste des stations associées 

types :

bss_cfg_name: perso|freewifi
filter_type=whitelist|blacklist
mac-address=adresse MAC de la carte réseau

commandes : (information extraite avec firebug) ; attention, les methodes sont des actions XML (XMLHttpRequest).
0 - éléments communs :
	csrf_token=TOKEN

1 - Wifi / configuration / valider
	method=wifi.ap_params_set
	enabled=on|off
	channel=1..13
	ht_mode=disabled|20|40_upper|40_lower (Mode 802.11n)

2 - Wifi / réseau personnel / paramêtres
	method=wifi.bss_params_set
	
	enabled=on|off
	hide_ssid=on|off
	ssid=votre-sid
	encryption=wep|wpa_psk_auto|wpa_psk_tkip|wpa_psk_ccmp|wpa2_psk_auto|wpa2_psk_tkip|wpa2_psk_ccmp
	key=votre-mot-de-passe
	mac_filter=disabled|whitelist|blacklist
	eapol_version=1|2 (Version du protocole EAPOL)
	config=Appliquer

3 - Wifi / réseau personnel / paramêtres avancés (identique 2)
	method=wifi.bss_params_set


4.1 - Wifi / réseau personnel / liste [blanche|noire] / ajouter
	method=wifi.mac_filter_add

	mac=<mac-address> ; exemple :  00:1F:3C:1E:45:63 (':' est encodé %3A) 
	comment=commentaire
	bss_cfg_name=perso|freewifi
	filter_type=whitelist|blacklist
	action=Ajouter

4.2 - Wifi / réseau personnel / liste blanche / supprimer
	method=wifi.mac_filter_del

	mac=<mac-address>
	filter_type=<whitelist|blacklist>
	action=Supprimer

5 - Wifi / réseau personnel / stations
	method=wifi.mac_filter_add

	comment=
	bss_cfg_name=perso
	mac=<mac-address>
	filter_type=whitelist
	action=Ajouter+%C3%A0+la+liste+blanche


*/

=end


class Wifi < Module

	def initialize fb
        super
        @name = 'wifi'
        @config=nil
	end

	def status_get
		self.exec('status_get')
	end

	def config_get
		self.exec('config_get')
	end
	
	def get_param(name)
		@config=self.get if(@config==nil)
		case name
			when 'enabled'
				return @config[:config]['ap_params']['enabled']
			when 'channel'
				return @config[:config]['ap_params']['channel']
			when 'ht_mode'
				return @config[:config]['ap_params']['ht']['ht_mode']
			when 'band'
				return @config[:config]['ap_params']['band']
			else
				raise "error : unknown parameter #{name}"
		end
	end
	def method_missing sym, *args
		case sym
			when :enabled?
				return self.get_param('enabled')=='true'
			when :enable
				return self.set_active(true)
			when :disable
				return self.set_active(false)
			when :channel=
				return self.set_channel(*args)
			else
				return self.get_param(sym.to_s)
		end
	end

	def get
		return {
			:status => self.status_get,
			:config => self.config_get,
		}
	end

	def stations_get
		self.exec('config_get')
	end

	# enabled=on|off
	# channel=1..13
	# ht_mode=disabled|20|40_upper|40_lower (Mode 802.11n)
	def ap_param_set cnf
		# current conf
		_cnf = { 
			'enabled' => self.enabled,
			'channel' => self.channel,
			'ht_mode' => self.ht_mode,
			'method'  => 'wifi.ap_params_set'
		}

		# override values from cnf hash
		cnf.each do |k,v|
			_cnf[k] = v
		end

		pp _cnf

		# reset cached config
		@config=nil
		return self.exec_xml('wifi.cgi', _cnf)

	end

	# active ou désactive la fonction wifi sur la freebox
	def set_active(status)
		cnf = {}
		case status
			when false, 'off'
				cnf['enabled'] = 'off'
			when true, 'on'
				cnf['enabled'] = 'on'
			else
				raise "error : unknow status (#{status})"
		end
		return ap_param_set(cnf)
	end
	
	# canal d'emission.
	def set_channel chan
		return ap_param_set({'channel' => chan})
	end
end

=begin

# résultat de la commande Wifi:get()

{:status=>
  {"detected"=>true,
   "bss"=>
    {"perso"=>
      {"has_wps"=>false,
       "bssid"=>"F4:CA:E5:C8:F1:70",
       "name"=>"perso",
       "active"=>true},
     "freewifi"=>
      {"has_wps"=>false,
       "bssid"=>"F4:CA:E5:C8:F1:71",
       "name"=>"freewifi",
       "active"=>true}},
   "active"=>true},
 :config=>
  {"bss"=>
    {"perso"=>
      {"name"=>"perso",
       "params"=>
        {"enabled"=>true,
         "ssid"=>"votre-ssid",
         "encryption"=>"wpa_psk_tkip",
         "hide_ssid"=>false,
         "allowed_macs"=>
          [{"mac"=>"00:08:10:75:B9:AB", "comment"=>"apm"},
           {"mac"=>"18:87:96:DA:5B:37", "comment"=>""}],
         "eapol_version"=>2,
         "key"=>"votre-mot-de-passe",
         "denied_macs"=>
          [{"mac"=>"00:1F:3C:1E:45:63", "comment"=>"votre-commentaire."},
           {"mac"=>"18:87:96:DA:5B:37", "comment"=>""}],
         "wps"=>{"enabled"=>false},
         "mac_filter"=>"disabled"}},
     "freewifi"=>
      {"name"=>"freewifi",
       "params"=>
        {"enabled"=>true,
         "ssid"=>"FreeWifi",
         "encryption"=>"none",
         "hide_ssid"=>false,
         "allowed_macs"=>{},
         "eapol_version"=>0,
         "key"=>"",
         "denied_macs"=>{},
         "wps"=>{"enabled"=>false},
         "mac_filter"=>"disabled"}}},
   "ap_params"=>
    {"enabled"=>true,
     "channel"=>6,
     "wmm"=>true,
     "ht"=>{"ht_mode"=>"disabled"},
     "band"=>"g"}}}

=end


class Extra < Module

	def initialize fb
        super
        @name = 'extra'
	end

	# retourne la liste des logiciels utilisés dans le firmware de la freebox.
	def legal
		# on récupère la listes des appels passés et recus, au format HTML
		body = self.http_get('/settings.php?page=misc_legal').body

		# le parser Nokogiri permettra de réaliser les extractions
		# après sélection des sections HTML (méthode css)
		page = Nokogiri::HTML(body)
		
		list = []

		# xpath : /html/body/div[4]/div[3]/table/tbody/tr
		# css : html body div#fluid div#col_1.scroll table tbody tr
		page.css('//div#col_1 tr').each { |tr|

			l = []
			tr.css('td').each { |td|
				l << self._trim(td.inner_text)
			}
			if l[0] != nil
				list << {
					:name    => l[0],
					:version => l[1],
					:licence => l[2],
					:url     => l[3]
				}
			end
		}
		
		return list
	end

	def _trim(str)
		return str.gsub(/[\s\n\r\t]+/, '')
		# return str.squeeze(" \t\n\r")
	end
end

=begin

RRD : extraction des graph RRD (connexion ADSL, signal/bruit, download)

 1) Internet / ADSL / statistiques / connexion ADSL : debit (up, down) et signal sur bruit (snr)
 http://{$url}/rrd.cgi?db=fbxdsl&type=snr&w=650&h=90&color1=00ff00&color2=ff0000&period=hour
 http://{$url}/rrd.cgi?db=fbxdsl&type=rate&dir=down&w=650&h=90&color1=00ff00&color2=ff0000&period=hour
 http://{$url}/rrd.cgi?db=fbxdsl&type=rate&dir=up&w=650&h=90&color1=00ff00&color2=ff0000&period=hour
 
 db=fbxdsl
 period = {hour|day|week}
 type={rate|snr}
 dir={down|up}
 w=650
 h=90
 color1=00ff00&color2=ff0000
 
 
 2) Internet / Statut : mesure débit utilisé (up, down)
 
 http://{$url}/rrd.cgi?db=fbxconnman&dir=up&period=day&w=650&h=90&color1=00ff00&color2=ff0000&ts=1359638606236
 http://{$url}/rrd.cgi?db=fbxconnman&dir=down&period=day&w=650&h=90&color1=00ff00&color2=ff0000&ts=1359638611251

=end

class Rrd < Module

	def initialize fb
        super
        @name = 'rrd'
        @periods = {
			:weekly  => 'week',
			:daily   => 'day',
			:hourly  => 'hour',
			:week  => 'week',
			:day   => 'day',
			:hour  => 'hour'
        }
        @directions = {
			:down  => 'down',
			:up    => 'up'
        }
        @types = {
			:rate  => 'rate',
			:snr   => 'snr'
        }
	end

	# récupère un graph RRD selon les paramêtres suivants :
	# - period : [:hour|:day|:week|:hourly|:weekly|:daily]
	# - direction : [:up|:down] - upload ou download
	# - opt peut contenir :
	#   - type : [:rate|:snr]
	#   - width 
	#   - height
	# - les valeurs par défaut sont dans la structure  def_opts 
	def get period, direction, opts={}

		# default options.
		def_opts = {
			:width  => 1000,
			:height => 200,
			:type => :rate      # :rate|:snr
			# :direction => :down # :down, :up
		}
		opts = def_opts.merge opts

		cgi='rrd.cgi'
		db='fbxconnman'
		extra=sprintf('&w=%d&h=%d&color1=00ff00&color2=ff0000', opts[:width],opts[:height])
		url = sprintf('%s?db=%s&type=rate&dir=%s&%s&period=%s', cgi, db, direction.to_s, extra, @periods[period])
		body = self.http_get(url).body
	end
end

end # module Mafreebox


