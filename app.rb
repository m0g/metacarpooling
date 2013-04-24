require 'sinatra'
require 'open-uri'
require 'nokogiri'
require 'addressable/uri'
require 'date'
require 'json'
require 'sinatra/r18n'

require_relative 'lib/result.rb'
require_relative 'lib/search.rb'
require_relative 'lib/covoiturage_fr.rb'
require_relative 'lib/mitfahrgelegenheit_de.rb'

class Metacarpooling < Sinatra::Base
  register Sinatra::R18n
  set :root, File.dirname(__FILE__)
end

get '/' do
  erb :index
end

post '/' do
  @results = [
    CovoiturageFr.new(params[:search]).process,
    MitfahrgelegenheitDe.new(params[:search]).process
  ].flatten
  #@results = MitfahrgelegenheitDe.new(params[:search]).process
  erb :results, locals: { results: @results,
                          search: params[:search] }
end

not_found do
  status 404
  'not found'
end
