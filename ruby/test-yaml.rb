#!/usr/bin/ruby

# http://www.ruby-doc.org/stdlib-1.8.7/libdoc/yaml/rdoc/YAML.html
require 'yaml'

cnf= ENV['HOME'] + '/.config/mafreebox.ymlxx'

if(File.exist?(cnf))
	config = YAML::load(File.open(cnf))

	# vous pouvez creer un fichier $HOME/.config/mafreebox.yml avec le contenu suivant :
	# :url: http://mafreebox.free.fr/
	# :login: freebox
	# :passwd: votre-mot-de-passe

else
	config = YAML::load(YAML::dump(
		:url		=> 'http://mafreebox.free.fr/', # ou votre adresse IP externe
		:login		=> 'freebox',
		:passwd		=> 'your-password'
	))

end

p config[:url]

