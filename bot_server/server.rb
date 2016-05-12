require 'json'
require 'redis'

NEW_TEAM_CHANNEL = 'new_teams'

class BotServer
  def initialize(redis)
    @redis = redis
  end
  
  def create(info)
    puts "Received info: #{info['team_id']}"
    self.store_team info
  end
  
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

redis.subscribe(NEW_TEAM_CHANNEL) do |on|  
  on.message do |channel, msg|
    # If this isn't on a new thread, Redis will stay in 'looking for info' mode
    # and timeout when you try and insert things
    Thread.new { bot_server.create JSON.parse(msg) }
  end
end
