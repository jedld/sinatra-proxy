require 'sinatra'
require 'open-uri'

get '/proxy' do
  url = params[:url]
  open(url) do |content|
    content.read.to_s
  end
end
