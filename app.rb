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
require 'pony'
require 'sinatra/base'
require 'sinatra/assetpack'
require 'rest_client'

# Core
require_relative 'lib/result.rb'
require_relative 'lib/search.rb'
require_relative 'lib/super_search.rb'
require_relative 'lib/feedback.rb'

# Helpers
require_relative 'lib/helpers/dates_international.rb'
require_relative 'lib/helpers/recaptcha.rb'
require_relative 'lib/helpers/translate.rb'
require_relative 'lib/helpers/geocoding.rb'

# Search engines
require_relative 'lib/engines/covoiturage_fr.rb'
require_relative 'lib/engines/mitfahrgelegenheit_de.rb'
require_relative 'lib/engines/bessermitfahren_de.rb'
require_relative 'lib/engines/mitfahrzentrale_de.rb'
require_relative 'lib/engines/fahrgemeinschaft_de.rb'
require_relative 'lib/engines/covoituragelibre_fr.rb'
require_relative 'lib/engines/mifaz_de.rb'
require_relative 'lib/engines/drive2day_de.rb'
require_relative 'lib/engines/blablacar.rb'

class Metacarpooling < Sinatra::Base
  set :root, File.dirname(__FILE__)

  register Sinatra::R18n
  register Sinatra::AssetPack

  assets {
    serve '/js', from: 'assets/js'
    js :application, [
      '/js/jquery.js',
      '/js/jquery-ui.js',
      '/js/metacarpooling.js'
    ]

    serve '/css', from: 'assets/css'
    css :application, [
      '/css/app.css',
      '/css/bootstrap.css',
      '/css/bootstrap-responsive.css',
      '/css/jquery-ui.css'
    ]

    js_compression  :uglify    # :jsmin | :yui | :closure | :uglify
    css_compression :simple   # :simple | :sass | :yui | :sqwish
  }
end

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
GOOGLE_ANALYTICS = settings.google_analytics
MFG_SECRET = settings.mfg_secret
ENGINES = settings.enabled_engines

helpers do
  def translated_date date
    [
      t.date.day.send(date.strftime('%A').downcase),
      date.strftime('%d'),
      t.date.month.send(date.strftime('%B').downcase),
      date.strftime('%Y')
    ].join ' '
  end
end

get '/' do
  if session[:locale]
    redirect "/#{session[:locale]}/"
  elsif env.has_key?('HTTP_ACCEPT_LANGUAGE') and not env['HTTP_ACCEPT_LANGUAGE'].empty?
    redirect "/#{env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first}/"
  else
    redirect "/en/"
  end
end

get '/:locale' do
  redirect "/:locale/"
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

    if fields = super_search.validate_fields and coordinates = super_search.validate_coordinates
      @results = super_search.process
      erb :results, locals: {
        results: @results,
        date: Date.strptime(params[:search][:when][:date], '%d-%m-%Y'),
        search: params[:search]
      }
    else
      if coordinates == false
        flash[:error] = :not_found
      elsif fields == false
        flash[:error] = :form_invalid
      end

      erb :index
      #redirect "/#{session[:locale]}/"
    end
  end
end

get '/:locale/about' do
  erb :about, locals: {
    markdown: RDiscount.new(File.open('content/about.md', 'r').read).to_html
  }
end

get '/:locale/feedback' do
  erb :feedback
end

post '/:locale/feedback' do
  feedback = Feedback.new params[:feedback]
  recaptcha = Recaptcha.new(
    params[:recaptcha_challenge_field],
    params[:recaptcha_response_field],
    env['REMOTE_ADDR']
  )
  json = Hash.new

  feedback_valid = feedback.valid?
  if recaptcha.valid? and feedback_valid
    json[:success] = true
    feedback.send
  else
    json = { success: false,
             recaptcha_error: recaptcha.error?.to_s,
             errors: feedback.errors_to_json }
  end

  content_type :json
  json.to_json
end

get '/en/terms_and_conditions' do
  erb :terms, locals: {
    markdown: RDiscount.new(File.open('content/terms_and_conditions.md', 'r').read).to_html
  }
end

get '/de/impressum' do
  erb :terms, locals: {
    markdown: RDiscount.new(File.open('content/impressum.md', 'r').read).to_html
  }
end

get '/fr/mentions_legales' do
  erb :terms, locals: {
    markdown: RDiscount.new(File.open('content/mentions_legales.md', 'r').read).to_html
  }
end

not_found do
  status 404
  erb :not_found
end
