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
require 'rack-flash'
require 'sinatra/config_file'

require_relative 'lib/result.rb'
require_relative 'lib/search.rb'
require_relative 'lib/super_search.rb'
require_relative 'lib/dates_international.rb'

# Search engines
require_relative 'lib/covoiturage_fr.rb'
require_relative 'lib/mitfahrgelegenheit_de.rb'
require_relative 'lib/bessermitfahren_de.rb'
require_relative 'lib/mitfahrzentrale_de.rb'
require_relative 'lib/fahrgemeinschaft_de.rb'
require_relative 'lib/covoituragelibre_fr.rb'

class Metacarpooling < Sinatra::Base
  register Sinatra::R18n
  set :root, File.dirname(__FILE__)
end

enable :sessions
use Rack::Flash

config_file 'config.yml'

COUNTRIES = settings.countries
AVAILABLE_COUNTRIES = settings.available_countries

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
  #MitfahrzentraleDe::get_countries
  #MitfahrgelegenheitDe::get_countries

  session[:locale] = params[:locale] if params[:locale]

  unless params.has_key? 'search'
    erb :index
  else
    super_search = SuperSearch.new params[:search]

    if super_search.validate_fields
      @results = super_search.process
      erb :results, locals: {
        results: @results,
        date: Date.strptime(params[:search][:when][:date], '%d-%m-%Y'),
        search: params[:search]
      }
    else
      flash[:error] = :form_invalid
      redirect "/#{session[:locale]}/"
    end
  end
end

get '/:locale/about' do
  erb :about
end

not_found do
  status 404
  'not found'
end
