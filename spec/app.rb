require 'spec_helper'

describe "Metacarpooling App" do

  before :each do
    @query = { search: { 
      from: { country: 'germany', city: 'Berlin', radius: '1' },
      to: { country: 'germany', city: 'Leipzig', radius: '1' },
      when: {
        date: (Date.today + 1).strftime('%d-%m-%Y'),
        margin: 0
      },
      booking: 'both'
    }}
  end

  it "should respond to GET" do
    get '/en/'
    last_response.should be_ok
  end

  it "should return results" do
    get '/en/', @query
    last_response.should be_ok
  end

  it "should return results in french" do
    get '/fr/', @query
    last_response.should be_ok
  end

  it "should return results in german" do
    get '/de/', @query
    last_response.should be_ok
  end

  it "Should return not found when the city name is invalid" do
    @query[:search][:from][:city] = 'Bbbberlin'
    @query[:search][:to][:country] = 'france'
    @query[:search][:to][:city] = 'trololo'

    get '/en/', @query
    last_response.should be_ok

    Nokogiri::HTML(last_response.body)
      .at_css('.not-found')
      .should be_true
  end

  it "Should return not found when the date is in the past" do
    @query[:search][:when][:date] = (Date.today - 1).strftime '%d-%m-%Y'

    get '/en/', @query
    last_response.body.should be_empty
  end

  it "Should return not found when destination is empty" do
    @query[:search][:to][:city] = ''

    get '/en/', @query
    last_response.body.should be_empty
  end

  it "should returns results with today's date" do
    @query[:search][:when][:date] = Date.today.strftime '%d-%m-%Y'

    get '/en/', @query
    last_response.body.should be_true
  end

  it "Should return an error when random symbol are inserted in the city name" do
    @query[:search][:from][:city] = 'Be^rlùù*n'

    get '/en/', @query
    last_response.should be_ok
  end

  it "Should return results when french selected" do
    @query[:search][:from] = { country: 'france', city: 'Lyon', radius: '1' }
    @query[:search][:to] = { country: 'france', city: 'Annecy', radius: '1' }
    @query[:search][:when][:date] = (Date.today + 2).strftime('%d-%m-%Y')

    get '/fr/', @query
    last_response.should be_ok
  end

  it "Should not be any result with 0 seats remaining" do
    get '/fr/', @query
    last_response.should be_ok

    Nokogiri::HTML(last_response.body).css('span.nb-places').each do |line|
      line.text.strip.to_i.should_not eq(0)
    end
  end

  it "Should return in blablacar.com for Lyon Paris trip" do
    @query[:search][:from] = { country: 'france', city: 'Lyon', radius: '1' }
    @query[:search][:to] = { country: 'france', city: 'Paris', radius: '1' }

    get '/en/', @query
    last_response.should be_ok

    blablacar_exists = false
    Nokogiri::HTML(last_response.body).css('span.service').each do |line|
      blablacar_exists = true if line.text.downcase.strip == 'blablacar.com'
    end

    blablacar_exists.should be_true
  end

  it "Should return results in BMF, FGS, MFG for Berlin to Hannover" do
    @query[:search][:from] = { country: 'germany', city: 'Berlin', radius: '1' }
    @query[:search][:to] = { country: 'germany', city: 'Hannover', radius: '1' }
    @query[:search][:booking] = 'no'

    get '/de/', @query
    last_response.should be_ok

    bmf_exists, fgs_exists = false
    Nokogiri::HTML(last_response.body).css('span.service').each do |line|
      bmf_exists = true if line.text.strip.downcase == 'bessermitfahren.de'
      fgs_exists = true if line.text.strip.downcase == 'fahrgemeinschaft.de'
    end

    bmf_exists.should be_true
    fgs_exists.should be_true
  end

  it "Should return results in Mifaz & FGS for Berlin to munich in EN" do
    @query[:search][:from] = { country: 'germany', city: 'Berlin', radius: '1' }
    @query[:search][:to] = { country: 'germany', city: 'Munich', radius: '1' }

    get '/en/', @query
    last_response.should be_ok

    fgs_exists, mifaz_exists = false
    Nokogiri::HTML(last_response.body).css('span.service').each do |line|
      fgs_exists = true if line.text.strip.downcase == 'fahrgemeinschaft.de'
      mifaz_exists = true if line.text.strip.downcase == 'mifaz.de'
    end

    fgs_exists.should be_true
    mifaz_exists.should be_true
  end

  it "Should return results in Mifaz & FGS for Berlin to munich in DE" do
    @query[:search][:from] = { country: 'germany', city: 'Berlin', radius: '1' }
    @query[:search][:to] = { country: 'germany', city: 'München', radius: '1' }

    get '/de/', @query
    last_response.should be_ok

    fgs_exists, mifaz_exists = false
    Nokogiri::HTML(last_response.body).css('span.service').each do |line|
      fgs_exists = true if line.text.strip.downcase == 'fahrgemeinschaft.de'
      mifaz_exists = true if line.text.strip.downcase == 'mifaz.de'
    end

    fgs_exists.should be_true
    mifaz_exists.should be_true
  end

  it "Should return results with Erfurt" do
    @query[:search][:from] = { country: 'germany', city: 'Berlin', radius: '1' }
    @query[:search][:to] = { country: 'germany', city: 'Erfurt', radius: '1' }

    get '/de/', @query
    last_response.should be_ok
  end

  it "Should return results with wrong city name" do
    @query[:search][:from] = { country: 'germany', city: 'Berlin', radius: '1' }
    @query[:search][:to] = { country: 'germany', city: 'Munchen', radius: '1' }

    get '/en/', @query
    last_response.should be_ok
  end
end
