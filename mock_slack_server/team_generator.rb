require 'erb'
require 'digest/sha1'

WS_URL = 'ws://localhost:8080'

class TeamGenerator
  FIRST_NAMES = [
    'green',
    'red',
    'purple',
    'mauve',
    'maroon',
    'magenta',
    'blue',
    'cyan',
    'turquoise',
    'yellow'
  ]
  LAST_NAMES = [
    'echidna',
    'horse',
    'dog',
    'cat',
    'squirrel',
    'pig',
    'elephant',
    'donkey',
    'sloth'
  ]
  def self.create_user(token)
    id = Digest::SHA1.hexdigest(token)
    first = FIRST_NAMES.sample.capitalize
    last = LAST_NAMES.sample.capitalize
    user = {
      name: "#{first}.#{last}".downcase,
      dm_id: id,
      id: id,
      real_name: "#{first} #{last}",
      first_name: first,
      last_name: last,
      email: "#{first}@#{last}.com",
    }
    user
  end
  
  def self.team_json(user)
    @@template ||= ERB.new(File.read(File.expand_path('team_template.json', File.dirname(__FILE__))))
    
    team = {
      id: Digest::SHA1.hexdigest(Time.now.to_s + 'team_id'),
      name: "Euston fishery",
      url: WS_URL + "/#{user[:token]}"
    }
    # This needs team, user and bot to generate the JSON
    @@template.result binding
  end
end

# puts TeamGenerator.create_team