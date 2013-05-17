require 'spec_helper'

describe "Metacarpooling App" do

  it "should respond to GET" do
    get '/en/'
    last_response.should be_ok
  end

end
