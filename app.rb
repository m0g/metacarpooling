require 'sinatra'
require 'open-uri'
require 'nokogiri'
require "addressable/uri"
require 'date'

require_relative 'lib/result.rb'
require_relative 'lib/search.rb'
require_relative 'lib/covoiturage_fr.rb'

get '/' do
  erb :index
end

post '/' do
  @results = CovoiturageFr.new(params[:search]).process
  erb :results, locals: { results: @results, 
                          search: params[:search] }
end

not_found do
  status 404
  'not found'
end
