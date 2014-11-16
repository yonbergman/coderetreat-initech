require 'sinatra'
require 'coffee-script'
set :haml, :format => :html5

get '/' do
  redirect '/initech'
end

get '/initech' do
  haml :index
end

get '/initech/onboarding' do
  haml :index
end

get '/application.js' do
  coffee :application
end

get '/application.css' do
  scss :application
end
