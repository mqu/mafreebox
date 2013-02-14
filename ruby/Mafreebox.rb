#!/usr/bin/ruby


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
		mafreebox = Mafreebox.new(config)
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

	mafreebox.unix.cp('/Disque dur/test/toto.txt','/Disque dur/test/titi.txt')
	mafreebox.unix.rm('/Disque dur/test/titi.txt')
	mafreebox.unix.get('/Disque dur/test/toto.txt')

	# invocation de la méthode reboot du module System.
	p mafreebox.system.reboot

=end

require 'net/http'
require 'json'
require 'yaml'

class Mafreebox

    def initialize config
		@modules = Hash.new

		@modules[:system]   = System.new(self)
		@modules[:fs]       = Fs.new(self)
		@modules[:unix]     = Unix.new(self)
		@modules[:download] = Download.new(self)

		@config = config
		@config[:cookie] = nil
		@config[:token] = nil
    end

	def login
		args = {
			'login'  => @config[:login],
			'passwd' => @config[:passwd]
		}

		response = self.post('login.php', args)

		@config[:cookie] = response['Set-Cookie']
		@config[:token] = response['x-fbx-csrf-token']

		return true
		
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
		http.read_timeout = 5
		http.open_timeout = 5

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
	  def method_missing(sym, *args)		
		return @modules[sym] if(@modules.has_key?(sym))
		super
	  end

	def uri cmd
		URI.parse(@config[:url] + cmd)
	end

end

class Module
	@fb

	def initialize fb
	        @fb = fb
	end
end


# System : 
# 
# - system.uptime_get() : retourne le temps écoulé depuis la mise en route de la freebox (en secondes)
# - system.mac_address_get() : adresse MAC de la FB
# - system.serial_get() : n° de série de la FB
# - system.reboot ([timeout]) : Redémarre la freebox (timeout = temps d'attente en secondes)
# - system.fw_release_get() : renvoie la version courante du firmware
# 
# - non documentées :
# - system.rotation_set(): 
# 
# a faire : récupérer les températures depuis code HTML, page "/settings.php?page=misc_system"
# 
#       <li>Température CPUm : <span style="color: black;">XX °C</span></li>
#       <li>Température CPUb : <span style="color: black;">XX °C</span></li>
#       <li>Température SW : <span style="color: black;">XX °C</span></li>
#       <li>Vitesse ventilateur : <span>XXXX RPM</span></li>

class System < Module

	def get_all
		return {
			'uptime'     => self.uptime_get,
			'serial'     => self.serial_get,
			'mac'        => self.mac_address_get,
			'fw-release' => self.fw_release_get,
		}
	end

	def uptime_get
		@fb.exec('system.uptime_get')
	end

	def mac_address_get
		@fb.exec('system.mac_address_get')
	end

	def serial_get
		@fb.exec('system.serial_get')
	end

	def reboot(timeout)
		@fb.exec('system.reboot', [timeout])
	end

	def fw_release_get
		@fb.exec('system.fw_release_get')
	end
end


# 
# Fs : Fonctions permettant de lister et de gérer les fichiers du NAS.
# 
# méthodes JSON :
# - fs.list(dir, opt) : liste les fichiers d'un répertoire donné. 
# - fs.get(file [, opt]) : récupère les données d'un fichier sur le disque. 
# - fs.operation_progress(id) : récupère l'état d'une tâche asynchrone en cours. 
# - fs.operation_list() : Récupère la liste de toutes les opérations asynchrones en cours. 
# - fs.abort(id) : tue une tâche en cours, 
# - fs.set_password(id, password) : fourni un mot de passe à l'opération asynchrone le requérant. La tâche doit être dans l'état 'waiting_password'. 
# - fs.move(from, to): déplace un ou des fichiers vers un nouveau répertoire. 
# - fs.copy(from, to): copie un ou des fichiers vers un nouveau répertoire. 
# - fs.remove(path): supprime définitivement un ou des fichiers. 
# - fs.unpack(archive [, destination]): Décompresse une archive dans le répertoire. Si le répertoire de destination n'est pas renseigné, décompresse dans le répertoire ou se trouve l'archive. 
# - fs.mkdir(path): Crée un répertoire sous /media étant donné son chemin 
# 
# correspondance méthodes :
# 
# - get() -> POST /get.php {filename=....},
# - get_json -> JSON : fs.get

class Fs < Module

	def list(path)
		@fb.exec('fs.list', [path])
	end

	def json_get(file, opts=nil)
		if(opts == nil)
			@fb.exec('fs.get', file)
		else
			@fb.exec('fs.get', [file, opts])
		end
	end

	def get(path)
		args= {
			'filename' => path
		}
		@fb.post('get.php', args).body
	end

	def copy(src, dest)
		@fb.exec('fs.copy', [src, dest])
	end

	def mkdir(path)
		@fb.exec('fs.mkdir', path)
	end

	def remove(path)
		@fb.exec('fs.remove', path)
	end

	def move(src, dest)
		@fb.exec('fs.move', [src, dest])
	end
end

class Unix < Fs

	def ls(path)
		self.list(path)
	end

	def mv(src, dest)
		self.move(src, dest)
	end

	def cp(src, dest)
		self.copy(src, dest)
	end

	def rm(path)
		self.remove(path)
	end

	def rmdir(path)
		self.remove(path)
	end

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

	def list()
		@fb.exec('download.list')
	end

	def config_get()
		@fb.exec('download.config_get')
	end

	def config_set(config)
		@fb.exec('download.config_set', config)
	end

	def http_add(name, url)
		@fb.exec('download.http_add', [name, url])
	end

end



