require 'drb/drb'
require 'json'
require 'redis'

URI = 'druby://localhost:3474'

class BotServer
  def initialize(redis)
    @redis = redis
  end
  
  def create(info)
    puts "Received info: #{info['team_id']}"
    self.store_team info
  end
  
  private
  def store_team(hash)
    team_id = hash['team_id']
    
    webhook_url = hash['incoming_webhook']['url']
    access_token = hash['access_token']
    bot_access_token = hash['bot']['bot_access_token']
    
    @redis["team:#{team_id}:webhook_url"] = webhook_url
    @redis["team:#{team_id}:access_token"] = access_token
    @redis["team:#{team_id}:bot_access_token"] = bot_access_token
    
    @redis.rpush 'team_ids', team_id
  end
end



redis = Redis.new
bot_server = BotServer.new redis

$SAFE = 1   # disable eval() and friends
DRb.start_service(URI, bot_server)
DRb.thread.join
