class Config
  PATH = '../config.json'
  
  def self.[](key)
    @config ||= load_config
    @config[key]
  end
  
  def self.to_s
    @config ||= load_config
    "Config(#{@config.to_s})"
  end
  
  private
  def self.load_config
    JSON.parse(File.read(File.expand_path(PATH, __FILE__)))
  end
end