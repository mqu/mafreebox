#!/usr/bin/ruby
# coding: utf-8

# author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL

require 'pp'

$LOAD_PATH.unshift '/home/marc/Bureau/Dev/github/mafreebox/ruby'

require 'Mafreebox.rb'
# require 'lib-extra/unidecoder.rb'

def usage
	puts "usage : appel-recus\n"
	puts "- liste les appels recus sur votre freebox"
end


cnf= ENV['HOME'] + '/.config/mafreebox.yml'

if(File.exist?(cnf))
	config = YAML::load(File.open(cnf))

	# vous pouvez creer un fichier $HOME/.config/mafreebox.yml avec le contenu suivant :
	# :url: http://mafreebox.free.fr/ (ou adresse IP externe)
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
#rescue
#	puts "connexion error :"
#	puts "- url : " + config[:url]
#	puts "- login : " + config[:login]
#	puts "- passwd : " + config[:passwd]
#	exit(-1)
end

logs = mafreebox.phone.logs

logs[:recus].each do |call|
	# printf("%s : %s\n", call[:tel], call[:nom], mafreebox.phone.date_parse(call[:heure])[:en], call[:duree])
	h = mafreebox.phone.date_parse(call[:heure])
	printf("%s : %s : %s : %s\n", call[:tel], call[:nom], h[:en], call[:duree])
end

