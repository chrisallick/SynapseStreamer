#\ -p 9306

require 'rubygems'
require 'bundler'

Bundler.require

require './config.rb'
require './app.rb'
run Sinatra::Application