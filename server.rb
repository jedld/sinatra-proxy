require 'sinatra'
require 'open-uri'
require 'yaml'
require 'httparty'
require 'json'

$config = YAML.load_file('config.yml')

get "/" do
  "OK"
end

get "/echo/*" do
  mapped_headers = {}
  headers.each do |k,v|
    mapped_headers[k] = v if v
  end
  content_type 'application/json'
  { headers: mapped_headers, params: params, path: request.path }.to_json
end

post "/echo/*" do
  mapped_headers = {}
  headers.each do |k,v|
    mapped_headers[k] = v if v
  end
  
  content_type 'application/json'
  { headers: mapped_headers, body: request.body, params: params, path: request.path }.to_json
end


$config['mapping'].each do |mapping|

  puts "mapping #{mapping['method'].upcase} #{mapping['path']} -> #{mapping['host']}"
  send(mapping['method'].to_sym, "#{mapping['path']}/*") do
    path = "#{mapping['host']}/#{request.path.gsub(mapping['path'],'')}"
    #build http party url
    mapped_headers = {}
    headers.each do |k,v|
      mapped_headers[k] = v if v
    end

    response = if mapping['method'].downcase == 'get'
      HTTParty.get(path, query: params, headers: mapped_headers)
    else
      HTTParty.post(path, body: request.body, headers: mapped_headers)
    end
    status response.code
    response.body
  end
end
