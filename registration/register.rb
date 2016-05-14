require 'sinatra'
require 'tilt/haml'
require 'pry'
require 'json'
require 'net/http'
require 'redis'
require_relative '../mock_slack_server/team_generator'

NEW_TEAM_CHANNEL = 'new_teams'
NEW_DEMO_CHANNEL = 'new_demos'

AUTH_URL = 'https://slack.com/api/oauth.access'

class AuthManager
  def initialize(redis, client_id, client_secret)
    @redis = redis
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
      @redis.publish NEW_TEAM_CHANNEL, res.body
      return cont
    else
      raise "Oh shit: #{res.code}"
    end
  end
  
  def create_mock_team(token)
    user = TeamGenerator.create_user(token)
    user[:token] = token
    puts user
    
    @redis.publish NEW_DEMO_CHANNEL, user.to_json
    return TeamGenerator.team_json(user)
  end
end

config = JSON.parse File.read(ARGV[0])

client_secret = config['client_secret']
client_id = config['client_id']

redis = Redis.new
auth_manager = AuthManager.new(redis, client_id, client_secret)

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

get '/api/rtm.start' do
  content_type :json
  token = params[:token]
  if token
    auth_manager.create_mock_team token
  else
    { ok: false, error: 'No token specified' }.to_json
  end
end

get '/fakeslack' do
  haml :fakeslack
end
