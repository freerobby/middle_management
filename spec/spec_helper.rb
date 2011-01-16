require 'middle_management'

# Backup and restore environment for each test
RSpec.configure do |config|
  config.before(:each) do
    @env_backup = Hash.new
    ENV.keys.each {|key| @env_backup[key] = ENV[key]}
  end
  config.after(:each) do
    @env_backup.keys.each {|key| ENV[key] = @env_backup[key]}
  end
end