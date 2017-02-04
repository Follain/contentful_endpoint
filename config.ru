require 'rubygems'
require 'bundler'

Bundler.require(:default)
require './lib/contentful_endpoint.rb'
run ContentfulEndpoint
