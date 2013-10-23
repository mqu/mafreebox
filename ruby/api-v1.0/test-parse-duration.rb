#!/usr/bin/ruby
# coding: utf-8

# author : Marc Quinton, février 2013, licence : http://fr.wikipedia.org/wiki/WTFPL

require 'pp'

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

pp parse_duration "1 minute"
#pp parse_duration "appel manqué"
#pp parse_duration "22 secondes"
#pp parse_duration "2 heures 33 minutes 21 secondes"
#pp parse_duration "2 heures"

