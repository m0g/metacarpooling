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

enable :sessions

get '/' do
  if session[:locale]
    redirect "/#{session[:locale]}/"
  else
    redirect "/en/"
  end
end

get '/:locale/' do
  session[:locale] = params[:locale] if params[:locale]

  unless params.has_key? 'search'
    erb :index
  else
    @results = [
      CovoiturageFr.new(params[:search]).process,
      MitfahrgelegenheitDe.new(params[:search]).process
    ].flatten
    erb :results, locals: { results: @results,
                            search: params[:search] }
  end
end

not_found do
  status 404
  'not found'
end
