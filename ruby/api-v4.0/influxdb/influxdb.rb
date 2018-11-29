#!/usr/bin/ruby
# coding: UTF-8


require 'pp'
require './FreeboxOS.rb'

# cnf= ENV['HOME'] + '/.config/mafreebox.yml'
cnf= './mafreebox.yml'

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
	# puts "authentification réussie"
else
	puts "authentification échouée"
	exit(1)
end

rest = Rest.new config[:api], login.session_token

# API V4
infos={}
infos[:conn]=rest.get('/connection')["result"]
infos[:syst]=rest.get('/system')["result"]

case infos[:conn]["media"]

when "xdsl"
	infos[:xdsl] = rest.get('/connection/xdsl')["result"]
when "ftth"
	infos[:ftth] = rest.get('/connection/ftth')["result"]

end

# pp infos

result={}

# bandwidth : debit max montant et descendant
result[:bw_up]   = 1.0 * infos[:conn]['bandwidth_up']/(1000*1000)    # bande passante max sens montant
result[:bw_down] = 1.0 * infos[:conn]['bandwidth_down']/(1000*1000)  # bande passante max sens descendant en Ko/s

# debits montant et descendant
result[:down] = 1.0 * infos[:conn]['rate_down']    # débit descendant Ko/s
result[:up]   = 1.0 * infos[:conn]['rate_up']      # débit montant Ko/s

# volumes telecharges
result[:bytes_down] = infos[:conn]['bytes_down']    # en octets
result[:bytes_up]   = infos[:conn]['bytes_up']      # 

# divers
result[:xdsl_uptime] = infos[:xdsl]['status']['uptime'] # uptime en secondes (de la connexion)

# signal / bruit
result[:sn_down] = 1.0 * infos[:xdsl]['up']['snr']        # 
result[:sn_up]   = 1.0 * infos[:xdsl]['down']['snr']        # 

# errors / counter
result[:fec_down] = infos[:xdsl]['up']['fec']        # 
result[:fec_up]   = infos[:xdsl]['down']['fec']        # 

# system
result[:temp_cpu1]  = infos[:syst]['temp_cpub']    # 2 CPU, 3 capteurs de température
result[:temp_cpu2]  = infos[:syst]['temp_cpum']    # 
result[:temp_sw]    = infos[:syst]['temp_sw']      # 
result[:fan_rpm]    = infos[:syst]['fan_rpm']      # vittesse rotation du ventilateur interne
result[:uptime]     = infos[:syst]['uptime_val']   # uptime de la box en secondes

puts result.to_json
