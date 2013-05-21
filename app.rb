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
require 'rdiscount'

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

#enable :sessions
use Rack::Session::Cookie, :key => 'rack.session',
                           :domain => 'metacarpooling.com',
                           :path => '/',
                           :expire_after => 2592000, # In seconds
                           :secret => 'a25856hjeprieyuxoe223965'
use Rack::Flash

config_file 'config.yml'

COUNTRIES = settings.countries
AVAILABLE_COUNTRIES = settings.available_countries
RECAPTCHA = settings.recaptcha

get '/' do
  if session[:locale]
    redirect "/#{session[:locale]}/"
  elsif env.has_key?('HTTP8ACCPET_LANGUAGE') and not env['HTTP_ACCEPT_LANGUAGE'].empty?
    redirect "/#{env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first}/"
  else
    redirect "/en/"
  end
end

get '/:locale/' do

  unless R18n.available_locales.any? {|locale| locale.code == params[:locale] }
    if session.has_key? :locale
      redirect "/#{session[:locale]}/"
    else
      redirect "/en/"
    end
  end

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

get '/get_countries' do
  raise env['REMOTE_ADDR'].inspect

  MitfahrzentraleDe::get_countries
  MitfahrgelegenheitDe::get_countries
end

get '/:locale/about' do
  erb :about, locals: {
    markdown: RDiscount.new(File.open('content/about.md', 'r').read).to_html
  }
end

get '/:locale/feedback' do
  erb :feedback
end

not_found do
  status 404
  erb :not_found
end
