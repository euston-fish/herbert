require 'sinatra'
require 'tilt/haml'
require 'pry'
require 'json'
require 'net/http'
require 'drb/drb'

BOT_SERVER_URI = 'druby://localhost:3474'

AUTH_URL = 'https://slack.com/api/oauth.access'

class AuthManager
  def initialize(bot_server, client_id, client_secret)
    @bot_server = bot_server
    @client_secret = client_secret
    @client_id = client_id
  end
  
  def get_auth_token(code)
    uri = URI(AUTH_URL)
    params = {
      client_id: @client_id,
      client_secret: @client_secret,
      code: code
    }
    uri.query = URI.encode_www_form(params)

    res = Net::HTTP.get_response(uri)

    if res.code.to_i == 200
      cont = JSON.parse res.body
      raise cont['error'] unless cont['ok']
      
      # Create the bot on another process
      @bot_server.create cont
      return cont
    else
      raise "Oh shit: #{res.code}"
    end
  end
end

DRb.start_service
bot_server = DRbObject.new_with_uri(BOT_SERVER_URI)

config = JSON.parse File.read(ARGV[0])

client_secret = config['client_secret']
client_id = config['client_id']

auth_manager = AuthManager.new(bot_server, client_id, client_secret)

get '/' do
  haml :index
end

get '/authenticate', layout: :main do
  if params['code']
    begin
      auth_manager.get_auth_token(params['code'])
    rescue Exception => e
      @error = e.message
    end
  end
  haml :success
end