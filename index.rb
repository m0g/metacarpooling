require 'sinatra'

get '/' do
  erb :index
end

post '/' do
  erb :results, locals: params
end

not_found do
  status 404
  'not found'
end
