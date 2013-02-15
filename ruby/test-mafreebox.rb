#!/usr/bin/ruby
# coding: utf-8

# author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL

require 'pp'
require './Mafreebox.rb'

def usage
	puts "usage : ruby test-mafreebox [module]\n"
	puts "- permet de tester l'usage et le fonctionnement des modules\n"
	puts "- liste des modules supportés : system, download, fs, unix\n"
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

if ARGV.count == 2
	puts("## send")
	p mafreebox.send(:system, 'uptime_get')
else
	case ARGV[0]
		when "json"
			# on récupère des enregistrements de cette forme : 
			# [{"type"=>"dir", "name"=>"Directory-name", "mimetype"=>"type-mime"}
			mafreebox.exec('fs.list', ['Disque dur/']).each { |e|
				printf("%s : %s : %s\n", e['type'], e['name'], e['mimetype'])
			}

		when "system"
			pp mafreebox.system.get_all
			
		when "conn"
			pp mafreebox.conn.get
			
		when "phone"
			pp mafreebox.phone.get
	
		when "ipv6"
			pp mafreebox.ipv6.get
	
		when "igd"
			pp mafreebox.igd.get
	
		when "lcd"
			pp mafreebox.lcd.get
			pp mafreebox.lcd.set(15) ; sleep(1) ; pp mafreebox.lcd.get
			pp mafreebox.lcd.set(75) ; sleep(1) ; pp mafreebox.lcd.get
			pp mafreebox.lcd.set(100) ; sleep(1) ; pp mafreebox.lcd.get

		when "share"
			pp mafreebox.share.get

		when "user"
			pp mafreebox.user.password_check_quality("123")

		when "lan"
			pp mafreebox.lan.get

		when "download"
			p mafreebox.download.list
			cfg = mafreebox.download.config_get
			p cfg
			cfg['max_dl'] = 100
			cfg['max_up'] = 50

			# FIXME : petit bug ici ... ? certains attributs semblent disparaitre de l'interface d'admin 
			# sont-ils écrasés ?
			mafreebox.download.config_set(cfg)
			sleep(1) ; p mafreebox.download.config_get

		when "unix"
			mafreebox.unix.ls('/Disque dur/').each { |e| printf("- %s\n", e['name'])} ; puts("\n")

			# scénario de test : 
			# - liste /Disque dur/test
			# - depuis /Disque dur/test ; 
			#   - copie toto.txt titi.txt cp(toto.txt", "titi.txt")
			#   - renome toto.txt -> mv
			#   - efface tutu.txt -> rm
			#   - crée un répertoire, le renomme et l'efface (mkdir, mv, rmdir)

			#	mafreebox.unix.ls('/Disque dur/test').each { |e| printf("- %s\n", e['name'])} ; puts("\n")
			#	mafreebox.unix.cp('/Disque dur/test/toto.txt','/Disque dur/test/titi.txt')
			#	sleep(1); mafreebox.unix.ls('/Disque dur/test').each { |e| printf("- %s\n", e['name'])} ; puts("\n")

			#	mafreebox.unix.mv('/Disque dur/test/titi.txt','/Disque dur/test/tutu.txt')
			#	sleep(1); mafreebox.unix.ls('/Disque dur/test').each { |e| printf("- %s\n", e['name'])} ; puts("\n")

			#	mafreebox.unix.rm('/Disque dur/test/tutu.txt')
			#	sleep(1); mafreebox.unix.ls('/Disque dur/test').each { |e| printf("- %s\n", e['name'])} ; puts("\n")

			#	mafreebox.unix.mkdir('/Disque dur/test/foobar')
			#	sleep(1); mafreebox.unix.ls('/Disque dur/test').each { |e| printf("- %s\n", e['name'])} ; puts("\n")

			#	mafreebox.unix.mv('/Disque dur/test/foobar', '/Disque dur/test/bar')
			#	sleep(1); mafreebox.unix.ls('/Disque dur/test').each { |e| printf("- %s\n", e['name'])} ; puts("\n")

			#	mafreebox.unix.rmdir('/Disque dur/test/bar')
			#	sleep(1); mafreebox.unix.ls('/Disque dur/test').each { |e| printf("- %s\n", e['name'])} ; puts("\n")

		when "fs"
			# p mafreebox.fs.list('/')
			# p mafreebox.fs.list('/Disque dur/')
			# p mafreebox.fs.json_get('/Disque dur/test/toto.txt') # FIXME : erreur !

			# require 'digest'
			# content = mafreebox.fs.get('/Disque dur/test/toto.txt')
			# printf("%s", Digest::MD5.hexdigest(content))

			# p mafreebox.fs.copy('/Disque dur/test/toto.txt', '/Disque dur/test/titi.txt')
			# p mafreebox.fs.remove('/Disque dur/test/titi.txt')
			# p mafreebox.fs.mkdir('/Disque dur/test/foobar')
			# p mafreebox.fs.move('/Disque dur/test/foobar', '/Disque dur/test/tutu')

	end
end


