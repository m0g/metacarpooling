require 'spec_helper'

describe "Metacarpooling App" do

  before :each do
    @query = { search: { 
      from: { country: 'germany', city: 'Berlin', radius: '1' },
      to: { country: 'germany', city: 'Leipzig', radius: '1' },
      when: {
        date: (Date.today + 1).strftime('%d-%m-%Y'),
        margin: ''
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

  it "Should return false when the city name is invalid" do
    @query[:search][:from][:city] = 'Bbbberlin'
    @query[:search][:to][:country] = 'france'
    @query[:search][:to][:city] = 'trololo'

    get '/en/', @query
    last_response.should be_ok
  end
end
