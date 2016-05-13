require 'erb'
require 'digest/sha1'

WS_URL = 'ws://localhost:8080'

class TeamGenerator
  def self.hash(content)
    Digest::SHA1.hexdigest content.to_s
  end
  
  def self.create_user
    user = {
      name: 'john.smith',
      dm_id: hash(Time.now.to_s + 'dm_id'),
      id: hash(Time.now.to_s + 'user_id'),
      real_name: 'John Smith',
      first_name: 'John',
      last_name: 'Smith',
      email: 'john@example.com',
    }
    user
  end
  
  def self.team_json(user, bot)
    @@template ||= ERB.new(File.read(File.expand_path('team_template.json', File.dirname(__FILE__))))
    
    team = {
      id: hash(Time.now.to_s + 'team_id'),
      name: "Euston fishery",
      url: WS_URL + "/#{user[:token]}"
    }
    # This needs team, user and bot to generate the JSON
    @@template.result binding
  end
end

# puts TeamGenerator.create_team