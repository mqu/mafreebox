#!/usr/bin/ruby

require 'json'

args = {
	:url		=> 'http://82.234.62.122/',
	:login		=> 'freebox',
	:passwd		=> 'azerty'
}

json = JSON.generate(args)
p json

p JSON.parse(json)

