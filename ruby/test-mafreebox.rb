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

case ARGV[0]
	when "json"
		# on récupère des enregistrements de cette forme : 
		# [{"type"=>"dir", "name"=>"Directory-name", "mimetype"=>"type-mime"}
		mafreebox.exec('fs.list', ['Disque dur/']).each { |e|
			printf("%s : %s : %s\n", e['type'], e['name'], e['mimetype'])
		}

	when "system"
		pp mafreebox.system.get
		# pp mafreebox.system.reboot
		
	when "conn"
		pp mafreebox.conn.get
		
	when "phone"
		pp mafreebox.phone.logs

	when "ipv6"
		pp mafreebox.ipv6.get

	when "extra"
		version = mafreebox.system.fw_release_get
		puts "# firmware : #{version}"
		puts mafreebox.export_csv(mafreebox.extra.legal)

	when "igd"
		pp mafreebox.igd.get

	when "blink"
		# mafreebox.lcd.blink
		mafreebox.lcd.blink_code(5)

	when "lcd"
		if ARGV.count == 2
			pp mafreebox.lcd.set(ARGV[1])
		else	
			pp mafreebox.lcd.get
		end

	when "share"
		pp mafreebox.share.get

	when "user"
		pp mafreebox.user.password_check_quality("123")

	when "lan"
		pp mafreebox.lan.get
		
	when "wifi"
		pp mafreebox.wifi.get

		if(ARGV[1] == 'set-active')
			pp ARGV
			case ARGV[2]
				when true
				when "true"
				when "on"
					puts "set-active = on"
					mafreebox.wifi.set_active(true)
				when false
				when "false"
				when "off"
					puts "set-active = off"
					mafreebox.wifi.set_active(false)
			end
		else
			pp mafreebox.wifi.get
		end
	when "download"
		p mafreebox.download.list

		# sleep(1) ; p mafreebox.download.config_get
		# pp mafreebox.download.http_add('ubuntu-12.10-server-amd64.iso', 'http://www-ftp.lip6.fr/pub/linux/distributions/Ubuntu/releases/12.10/ubuntu-12.10-server-amd64.iso')
		# sleep 1 ; pp mafreebox.download.list

		pp mafreebox.download.config_get
		
		config = {
			'download_dir'=>'/Disque dur/Téléchargements',
			'seed_ratio'  =>4,
			'max_peer'    =>30,
			'max_dl'      =>30,
			'max_up'      =>20
		}
		# FIXME : ne fonctionne pas comme escompté ....
		# pp mafreebox.download.config_set(config)


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


