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
require_relative 'lib/mitfahrgelegenheit_de.rb'
require_relative 'lib/mitfahrzentrale_de.rb'

MitfahrzentraleDe::get_countries
MitfahrgelegenheitDe::get_countries
