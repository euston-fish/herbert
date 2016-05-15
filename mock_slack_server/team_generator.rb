require 'erb'
require 'digest/sha1'
require '../config'

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
    'wolf',
    'tiger',
    'unicorn',
    'pig',
    'boar',
    'sheep',
    'dromedary',
    'elephant',
    'hamster',
    'chick'
  ]
  
  def self.create_user(token)
    id = Digest::SHA1.hexdigest(Time.now.to_s + 'user_id')
    rand = token.split(//).reduce(0) { |n, c| n + c.ord }
    first = FIRST_NAMES[rand % 10]
    last = LAST_NAMES[(rand / 10) % 10]
    avatar = "/avatars/#{last}.png"
    
    user = {
      name: "#{first.capitalize}.#{last.capitalize}".downcase,
      dm_id: id,
      id: id,
      real_name: "#{first} #{last}",
      first_name: first,
      last_name: last,
      email: "#{first}@#{last}.com",
      avatar: avatar
    }
    user
  end
  
  def self.team_json(user)
    @@template ||= ERB.new(File.read(File.expand_path('team_template.json', File.dirname(__FILE__))))
    
    team = {
      id: Digest::SHA1.hexdigest(Time.now.to_s + 'team_id'),
      name: "Euston fishery",
      url: Config['websocket_url'] + "/#{Digest::SHA1.hexdigest(user[:token] + user[:dm_id])}"
    }
    # This needs team, user and bot to generate the JSON
    @@template.result binding
  end
end
