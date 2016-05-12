require 'erb'

class TeamGenerator
  def self.create_team
    @@template ||= ERB.new(File.read('team_template.json'))
    
    team = {
      id: 'TEAM ID',
      name: "Euston fishery",
      url: 'google.com'
    }
    user = {
      name: 'john.smith',
      dm_id: 'as;dlfkjasdf',
      id: 'asdf',
      real_name: 'John Smith',
      first_name: 'John',
      last_name: 'Smith',
      email: 'john@example.com',
    }

    @@template.result binding
  end
end

puts TeamGenerator.create_team