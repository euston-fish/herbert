require 'sinatra'
require 'tilt/haml'
require 'pry'
require 'json'
require 'net/http'
require 'drb/drb'

BOT_SERVER_URI = 'druby://localhost:3474'

AUTH_URL = 'https://slack.com/api/oauth.access'
CLIENT_ID = '41856466277.41899110561'
SECRET = '453b28f8b8ce9a1b739535944a28d9e7'

# {"ok"=>true, "access_token"=>"xoxp-41856466277-41856466341-41923735716-d4cdc5e9ed", "scope"=>"identify,bot,incoming-webhook", "user_id"=>"U17R6DQA1", "team_name"=>"euston.fish", "team_id"=>"T17R6DQ85", "incoming_webhook"=>{"channel"=>"#general", "channel_id"=>"C17QVP760", "configuration_url"=>"https://eustonfish.slack.com/services/B17T8AQHL", "url"=>"https://hooks.slack.com/services/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"}, "bot"=>{"bot_user_id"=>"U17SB32UX", "bot_access_token"=>"xoxb-41895104983-JzXILx1NcsDbD2WVznWy1OJG"}}
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
      puts res.body
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

config = JSON.parse File.open(ARGV[1])

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