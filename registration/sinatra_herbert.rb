require 'sinatra/base'
require 'digest/sha1'
require 'tilt/haml'
require 'json'
require 'redis'
require_relative 'auth_manager'
require_relative '../config'

class SinatraHerbert < Sinatra::Base
  
  client_secret = Config['client_secret']
  client_id = Config['client_id']

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

  get '/demo' do
    @token = Digest::SHA1.hexdigest(Time.now.to_s + 'token')
    haml :demo
  end

  get '/timesheet/:user/?:num_days?' do
    user = params[:user]
    @day_cutoff = if params[:num_days].to_i == 0
      7.days.ago
    else
      [params[:num_days].to_i, 7].min.days.ago
    end
    if user.length > 0
      @actions = Action.where('user_id=? AND timestamp > ?', user, @day_cutoff).all
    end
    haml :timesheet
  end
  
  get '/404' do
    haml :'404'
  end
end
