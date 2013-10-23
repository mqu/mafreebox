#!/usr/bin/ruby
# coding: utf-8

# author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL

require 'pp'
require 'rubygems'
require 'sequel'
require 'mechanize'

[
  '/home/marc/Bureau/Dev/github/mafreebox/ruby',
  # '/home/marc/mafreebox/ruby',
  '.'
].each { |dir| $LOAD_PATH.unshift dir}


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



class PhoneEntry
	def initialize args
		@values = args
	end
	
	def to_s
		return sprintf("%s %s (%s)\n - %s", @values[:phone], @values[:name], @values[:type].to_s, @values[:addr].join(' ') )
	end
end

class Annu

	def initialize
		@url = 'http://www.annu.com/includes/resultats.php'
		@agent = Mechanize.new
	end

	def search search_str
		page = @agent.post(@url, {
		  "q" => search_str,
		})
		list = []
		
		# particuliers
		page.parser.css('#particuliers ol.list li.entry').each  do |e|

			# replace <br> by "\n"
			e.css('br').each{ |br| br.replace("\n") }

			list << PhoneEntry.new({
				:name  => e.search('h2').text,
				:phone => e.search('.phone span')[0].text,
				:addr => e.search('.adr p').text.split("\n"),
				:type => :particulier
				# :fax => e.search('.phone span')[1].text
			})
		end

		# professionnels
		page.parser.css('#professionnels ol.list li.entry').each  do |e|

			# replace <br> by "\n"
			e.css('br').each{ |br| br.replace("\n") }

			list << PhoneEntry.new({
				:name  => e.search('h2').text,
				:phone => e.search('.phone span')[0].text,
				:addr => e.search('.adr p').text.split("\n"),
				:type => :professionnel
				# :fax => e.search('.phone span')[1].text
			})
		end
		
		return list
	end
end


DB = Sequel.connect('sqlite://var/appels.db')

class Appel < Sequel::Model(:appels)
end

class Nom < Sequel::Model(:noms)

	def insert rec
		self[:nom] = rec[:nom]
		self[:tel] = rec[:tel]
		self[:mobile] = rec[:mobile]
		self[:comments] = rec[:comment]
		self.save
	end

	def to_s
		return sprintf "%s : %s : %s : %s", self[:nom], self.nil_to_s(self[:tel]), self.nil_to_s(self[:mobile]), self[:comments]
	end
	
	def nil_to_i v
		v==nil ? 0 : v
	end
	
	def nil_to_s v
		v==nil ? '-' : v.to_s
	end
end

class Appel < Sequel::Model(:appels)

	def to_s
		return sprintf "%13s : %17s : %s : %s", self[:tel], self[:nom], self[:date], self[:duree]
	end
end


class Db
	def initialize
		# self.create unless File.exists? @db
	end
	
	def create

		DB.drop_table(:appels) if DB.table_exists?(:appels)
		DB.drop_table(:noms) if DB.table_exists?(:noms)

		DB.create_table :appels do
		  primary_key :id
		  Datetime :date
		  Integer :duree
		  String :tel
		  String :nom
		end
		
		DB.create_table :noms do
		  primary_key :id
		  String :nom
		  String :tel
		  String :mobile
		  String :comments
		end
	end

	def last
		appels = DB[:appels]
		last=appels.order(:date).last
	end

	def select_all
		if block_given?
			# Appel.select_all.each do |appel|
			Appel.limit(50).order(:date).reverse.each do |appel|
				yield appel
			end
		else
			Appel.select_all
		end
	end
	
	def update call
		appel = Appel.new
		
		appel[:date]  = call[:date][:en]
		appel[:duree] = call[:duree]
		appel[:tel]   = call[:tel]
		appel[:nom]   = call[:nom]
		appel.save
		
		return appel
	end
end

class Noms < Db
	def initialize db
		@db = DB[db]
		@values={}
		self.load
	end
	
	def load
		@db.select_all.each do |rec|
			@values[rec[:tel]] = rec[:nom] unless rec[:tel] == ''
			@values[rec[:mobile]] = rec[:nom] unless rec[:mobile] == ''
		end
	end
	
	def exists? key
		return @values.has_key? key
	end
	alias has_key? exists?
	
	def [] key
		return @values[key] if self.exists? key
		return nil
	end
end

def do_cmd cmd, config

	begin
		mafreebox = Mafreebox::Mafreebox.new(config)
		# throws an exception on login or connexion error
		mafreebox.login
	#rescue
	#	puts "connexion error :"
	#	puts "- url : " + config[:url]
	#	puts "- login : " + config[:logrequire 'pp'
	#	puts "- passwd : " + config[:passwd]
	#	exit(-1)
	end

	case cmd

	when 'help', '-h'
		puts <<END
command usage : appels-db [help|db:create|show|fb:show|update|add]
 - update : mise à jour de la base de données locale depuis la freebox
 - show : affiche les derniers appels par ordre chronologique inverse
 - add : ajoute une entrée au répertoire local 
	add 'nom' telephone-fixe [tel-mobile [commentaire]]
 - fb:show : affiche le contenu de la table des appels depuis la freebox
 - search : recherche dans l annuaire (annu.com) (n° ou titulaire)
 - find : recherche en base suivant expression

END
	when 'db:create'

		db=Db.new.create

	when 'db:show', 'show'
		noms = Noms.new :noms
		count=0
		Db.new.select_all do |appel|
			appel[:nom] = noms[appel[:tel]] if noms.exists?(appel[:tel])
			puts appel
			count +=1
			puts "\n" if count %5==0 && count!=0
		end

	when 'db:last'
		# get last record in DB.
		pp Db.new.last

	when 'fb:show'

		logs = mafreebox.phone.logs

		logs[:recus].each do |call|
			printf("%s : %s : %s : %s\n", call[:tel], call[:nom], call[:date][:en], call[:duree])
		end

	when 'show:new'

		logs = mafreebox.phone.logs
		last = Db.new.last

		logs[:recus].select { |call| call[:date][:time_t] > last[:date].to_i }.each do |call|
			printf("+ %s : %s : %s : %s\n", call[:tel], call[:nom], call[:date][:en], call[:duree])
		end

	when 'db:update', 'update'

		# get last record in DB.
		db = Db.new
			
		logs = mafreebox.phone.logs

		logs[:recus].select { |call| call[:date][:time_t] > db.last[:date].to_i }.each do |call|
			printf "+ %s\n", db.update(call)
		end

	# annuaire inversés :
	# suisse : http://tel.search.ch/index.fr.html
	# france : annu.com
	when 'db:noms:add', 'add'
		rec = {
			:nom     => ARGV[1],
			:tel     => ARGV[2]==nil ? '' : ARGV[2].delete('.'),
			:mobile  => ARGV[3]==nil ? '' : ARGV[3].delete('.'),
			:comment => ARGV[4]==nil ? '' : ARGV[4].delete('.')
		}
		Nom.new.insert(rec)

	when 'db:nom:find'
		
		tel='05619252'
		names = DB[:noms]
		pp names.where('tel = ?', tel).all

		pp names[:tel=>tel, :mobile=>tel]

	# find ARG (tel, nom)
	when 'find'
		tel=ARGV[1]
		DB[sprintf("SELECT * FROM appels WHERE tel LIKE '%%%s%%' OR nom LIKE '%%%s%%' ORDER BY date DESC", tel, tel)].all.each do |appel|
			puts appel
		end


	when 'csv:read'

		lines=CSV.read(ARGV[1], opt={:col_sep=>':'}).each do |rec|
			Nom.new.insert(
				:nom     => rec[0],
				:tel     => rec[1]==nil ? '' : rec[1].delete('.'),
				:mobile  => rec[2]==nil ? '' : rec[2].delete('.'),
				:comment => ''
			)
		end

	when 'search', 'annu'

		annu = Annu.new
		annu.search(ARGV[1]).each do |e|
			puts e
			puts "\n"
		end

	end

end

if ARGV.size == 0
	cmd='show'
else
	cmd=ARGV[0]
end

do_cmd cmd, config

