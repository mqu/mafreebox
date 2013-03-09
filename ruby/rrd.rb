#!/usr/bin/ruby
# coding: utf-8

# author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL

require 'date'
require 'pp'
require './Mafreebox.rb'


def file_write _file, data
	File.open(_file,'w') {|file| file.puts data}
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

(usage && exit(0)) if ARGV.length == 0

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

opts = {
	:width  => 1000,
	:height => 200,
	:type => :rate  # :rate|:snr
}

period = ARGV[0]
time = Time.now
d=Date.today
direction=:download # :download, :upload

case period
	when "weekly"
		img = mafreebox.rrd.get :weekly, direction, opts
		file = sprintf('var/week/%d-%d-down.png', d.cwyear, d.cweek)
		file_write(file, img)
	when "daily"
		img = mafreebox.rrd.get :daily, direction, opts
		file = sprintf('var/day/%d-%d-down.png', d.cwyear, d.yday)
		file_write(file, img)
	when "hourly"
		img = mafreebox.rrd.get :hourly, direction, opts
		file = sprintf('var/hour/%d.%d.%d-%d-down.png', d.cwyear, Time.now.month, Time.now.day, DateTime.now.hour)
		file_write(file, img)
end


