#!/usr/bin/ruby
# coding: UTF-8

=begin

implement l'API V4 de la Freebox (Freebox OS) : 
 - http://dev.freebox.fr/sdk/os/ ; http://dev.freebox.fr/sdk/os/genindex/
 - http://mafreebox.freebox.fr/doc/
 
dépendances :
 - RestClient : https://github.com/rest-client/rest-client
 - sur ubuntu, debian : apt-get install ruby-rest-client

liens :

 - https://gist.github.com/mqu/5886096
 - http://dev.freebox.fr/sdk/os/

bug-tracker :
 - http://bugs.freeplayer.org/task/12683
 - http://bugs.freeplayer.org/index.php?tasks=&project=9&string=&type=&sev=&due=&dev=&cat=129&status=&date=0
 
=end

require 'net/http'
require 'yaml'
require 'uri'
require 'json'
require 'base64'
require 'pp'

require 'rest_client' # https://github.com/rest-client/rest-client ; apt-get install ruby-rest-client

# http://dev.freebox.fr/sdk/os/#freebox-discovery
class API

	# {
	#   uid: "23b86ec8091013d668829fe12791fdab",
	#   device_name: "Freebox Server",
	#   api_version: "1.0",
	#   api_base_url: "/api/",
	#   device_type: "FreeboxServer1,1"
	# }

	def self.infos
		url = 'http://mafreebox.freebox.fr/api_version'
		uri = URI.parse(url)
		info = Net::HTTP.get_response(uri)
		return JSON::parse(info.body)
	end
	
	def self.version
		self.version['api_version']
	end
end

class Rest
	
	def initialize url, session_token=nil
		@url = url
		
		if session_token != nil
			@headers = {
				"X-Fbx-App-Auth" => session_token
			}
		else
			@headers = nil
		end
	end

	def get method
		# puts "Rest::get(#{@url + method})\n"
		return JSON::parse(RestClient.get(@url + method, @headers))
	end
	
	def post method, args=nil
		# puts "Rest::post(#{@url + method})\n"
		case args
			when nil
				return JSON::parse(RestClient.post(@url + method, nil, @headers))
			else
				return JSON::parse(RestClient.post(@url + method, args.to_json, @headers))
		end
	end
end

class Core
	def initialize rest
		# rest client
		@rest = rest
	end

	def get method
		# puts "Core::get(#{method})"
		return @rest.get method
	end
	
	def put *args
		return @rest.put *args
	end

	def post *args
		return @rest.post *args
	end
	def delete *args
		return @rest.delete *args
	end	
	def delete *args
		return @rest.delete *args
	end	
end


# http://dev.freebox.fr/sdk/os/login/
class Login < Core

	def initialize rest
	
		super rest

		@_login=nil
		@session=nil
		@config = {
			:app_id       => 'fr.freebox.os.lib.ruby',
			:app_name     => 'ruby FreeboxOS library / MQU',
			:app_version  => '0.0.1'
		}
	end
	
	def api
		return API.infos
	end

	# récupérer un token pour l'authentification
	# cette méthode nécessite d'être en proximité de la freebox pour valider la tentative d'accès
	# sur la freebox, un message est affiché avec le nom de l'application ; il suffit de valider (ou pas).
	# avec les touches de défilement < >
	#
	# POST /api/v1/login/authorize/ HTTP/1.1
	# {
	#	"app_id": "fr.freebox.testapp",
	#	"app_name": "Test App",
	#	"app_version": "0.0.7",
	#	"device_name": "Pc de Xavier"
	# }
	#
	# response example
	# {
	#	"success": true,
	#	"result": {
	#	"app_token": "dyNYgfK0Ya6FWGqq83sBHa7TwzWo+pg4fDFUJHShcjVYzTfaRrZzm93p7OTAfH/0",
	#	"track_id": 42
	#	}
	# }
	
	def authorize name='fr.freebox.os.lib.ruby'
		args = {
			'app_id'      => @config[:app_id],
			'app_name'    => @config[:app_name],
			'app_version' => @config[:app_version],
			'device_name' => name
		}
		return post('/login/authorize/', args)
	end

	def authorization_status id
		return get('/login/authorize/' + id.to_s)
	end
	
	def login token
		@session = self.session({
				'app_id' => @config[:app_id],
				'password' => self.hmac_sha1(token, self.get_challenge)
			})
		return @session['success']
	end

	# GET /api/v1/login/ HTTP/1.1
	# Example response:
	# HTTP/1.1 200 OK
	# {
	# 	"success": true,
	#	"result": {
	#		"logged_in": false,
	#		"challenge": "VzhbtpR4r8CLaJle2QgJBEkyd8JPb0zL"
	#	}
	#}
	def _login
		return @_login unless @_login==nil
		# make @_login in cache
		@_login = get('/login/')
	end

	def session args
		return post('/login/session/', args)
	end

	def session_token
		raise "there is no session now (not connected yet)" if @session==nil
		return @session['result']['session_token']
	end

	def get_challenge
		return self._login['result']['challenge']
	end

	# usage : hmac_sha1(challenge, app_token)
	def hmac_sha1 key, signature
		require 'openssl'
		return OpenSSL::HMAC.hexdigest('sha1', key, signature)
	end

end

class Calls < Core

	def initialize rest_client
		super rest_client
	end

	def log id=nil
		if id==nil
			return self.get('/call/log/')
		else
			return self.get('/call/log/'+id.to_s)
		end
	end
	alias list log
	
	# à tester
	def delete id
		return self.delete('/call/log/' + id.to_s, args)
	end
	alias del delete

	# à tester
	def update id, args
		return self.put('/call/log/' + id.to_s, args)
	end
end

class Ftp < Core

	def initialize rest_client
		super rest_client
	end
	
	# à tester
	def get
		super ('/ftp/config')
	end
	
	# à tester
	def put args
		return put('/ftp/')
	end
end


# testing class
if __FILE__ == $0

cnf= ENV['HOME'] + '/.config/mafreebox.yml'

if(File.exist?(cnf))
	config = YAML::load(File.open(cnf))

	# vous pouvez creer un fichier $HOME/.config/mafreebox.yml avec le contenu suivant :
	# :url: http://mafreebox.free.fr/ (ou adresse IP externe)
	# :login: freebox
	# :passwd: votre-mot-de-passe

else
	config = YAML::load(YAML::dump(
		:api		=> 'http://mafreebox.freebox.fr/api/v1', # ou votre adresse IP externe
		:app_token	=> '+8gXzrE9GxxxEbDmjWB0C+SHWbH1LWS0JFTZv/pVPbNeYMIcSTimu/cwGMIMs1sA',  # exemple de token
		:track_id	=> 'XXX'
	))

end

# puts "config:"
#pp config
# pp API.infos ; exit 0


rest = Rest.new config[:api]
login = Login.new(rest)

# s'il y a des pb d'authorisation, il faut réactiver une session avec cette methode
# valider sur le freebox en touchant l'affichage (fleche)
# puis saisir dans les parametres la nouvelle config
# pp login.authorize()
if login.authorization_status(config[:app_track_id])['result']['status'] != 'granted'
	puts "l'application n'a pas été authorisée, ou ne l'est plus"
end

if login.login(config[:app_token])
	puts "authentification réussie"
else
	puts "authentification échouée"
	exit(1)
end

rest = Rest.new config[:api], login.session_token

# calls = Calls.new rest
# pp calls.list

# ftp = Ftp.new rest
# pp ftp.get

# pp rest.get('/call/log/')

# pp rest.get('/ftp/') 
# pp rest.get('/netshare/samba/')
# pp rest.get('/connection/config/') # http://mafreebox.freebox.fr/api/v1/connection/config/?_dc=1372611154541
# pp rest.get('/contact/')
# pp rest.get('/contact/3')
# pp rest.get('/parental/config')
# pp rest.get('/downloads/config/')
# pp rest.get('/downloads/throttling')

#dir = Base64.encode64('/Disque Dur') # L0Rpc3F1ZSBEdXI=
#puts dir
#puts Base64.decode64('L0Rpc3F1ZSBkdXI=')
#pp rest.get('/fs/ls/' + dir)


# fonctions cachées (non documentées, mais présentes sur FreeboxOS)
# pp rest.get('/connection/full/')
# pp rest.get('/system')

# API V4
# pp rest.get('/connection')
# pp rest.get('/connection/config')
# pp rest.get('/connection/ipv6/config')

# si /connection/media==xdsl
# pp rest.get('/connection/xdsl')
# si /connection/media==ftth
# pp rest.get('/connection/ftth')

end
