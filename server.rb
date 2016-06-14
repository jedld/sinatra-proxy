require 'sinatra'
require 'open-uri'
require 'yaml'
require 'httparty'
require 'json'
require 'active_support/all'

$config = YAML.load_file('config.yml')

def get_headers
  Hash[*env.select {|k,v| k.start_with?('HTTP_') || (k == 'CONTENT_TYPE') }
  .collect {|k,v| [k.sub(/^HTTP_/, ''), v]}
  .collect {|k,v| [k.split('_').collect(&:capitalize).join('-'), v]}
  .sort
  .flatten].except('Host', 'Connection', 'Version', 'X-Forwarded-For', 'X-Forwarded-Port', 'X-Forwarded-Proto')
end

get "/" do
  "OK"
end

get "/echo/*" do
  mapped_headers = get_headers

  content_type 'application/json'
  { headers: mapped_headers, params: params.except('splat', 'captures'), path: request.path }.to_json
end

post "/echo/*" do
  mapped_headers = get_headers

  content_type 'application/json'
  { headers: mapped_headers, body: request.body, params: params.except('splat', 'captures'), path: request.path }.to_json
end


$config['mapping'].each do |mapping|

  puts "mapping #{mapping['method'].upcase} #{mapping['path']} -> #{mapping['host']}"
  send(mapping['method'].to_sym, "#{mapping['path']}/*") do
    begin
      path = "#{mapping['host']}/#{request.path.gsub(mapping['path'],'')}"
      #build http party url
      mapped_headers = get_headers
      # puts({ endpoint: path, headers: mapped_headers, body: request.body.read.to_s, params: params.except('splat', 'captures'), path: request.path }.to_json)
      response = if mapping['method'].downcase == 'get'
        HTTParty.get(path, query: params.except('splat', 'captures'), headers: mapped_headers)
      else
        HTTParty.post(path, body: request.body.read.to_s, headers: mapped_headers)
      end
      status response.code
      response.body
    rescue StandardError => e
      puts e.message
      puts e.backtrace
      status 500
      { error: e.message, headers: mapped_headers, body: request.body, params: params.except('splat', 'captures'), path: request.path }.to_json
    end
  end
end
