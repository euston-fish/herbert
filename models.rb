require 'sinatra/activerecord'
require_relative 'config.rb'

ActiveRecord::Base.establish_connection(Config['db'])

class Action < ActiveRecord::Base
  default_scope { order('timestamp DESC') }
end
