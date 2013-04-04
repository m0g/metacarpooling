require 'sinatra'

class Result
  def initialize name, phone
    @name = name
    @phone = phone
  end

  def name
    @name
  end

  def phone
    @phone
  end
end

class Search
  def get_results
    [
      Result.new('Jean', '0450688799'),
      Result.new('Pierre', '0450688708')
    ]
  end

  def initialize search
    @search = search
  end
end

get '/' do
  erb :index
end

post '/' do
  @results = Search.new(params[:search]).get_results
  erb :results, locals: { results: @results }
end

not_found do
  status 404
  'not found'
end
