require 'sinatra'
require 'open-uri'
require 'net/http'
require 'nokogiri'
require 'addressable/uri'
require 'date'
require 'json'
require 'sinatra/r18n'
require 'unicode'
require 'text'

require_relative 'lib/result.rb'
require_relative 'lib/search.rb'
require_relative 'lib/super_search.rb'
require_relative 'lib/dates_international.rb'

# Search engines
require_relative 'lib/covoiturage_fr.rb'
require_relative 'lib/mitfahrgelegenheit_de.rb'
require_relative 'lib/bessermitfahren_de.rb'
require_relative 'lib/mitfahrzentrale_de.rb'

class Metacarpooling < Sinatra::Base
  register Sinatra::R18n
  set :root, File.dirname(__FILE__)
end

enable :sessions

get '/' do
  if session[:locale]
    redirect "/#{session[:locale]}/"
  elsif not env['HTTP_ACCEPT_LANGUAGE'].empty?
    redirect "/#{env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first}/"
  else
    redirect "/en/"
  end
end

get '/:locale/' do
  MitfahrzentraleDe::get_countries
  session[:locale] = params[:locale] if params[:locale]

  unless params.has_key? 'search'
    erb :index
  else
    @results = SuperSearch.new(params[:search]).order_by_date
    erb :results, locals: { results: @results,
                            search: params[:search] }
  end
end

not_found do
  status 404
  'not found'
end
