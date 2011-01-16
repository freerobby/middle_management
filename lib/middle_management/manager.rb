require 'heroku'

module MiddleManagement
  class Manager
    def self.enforce_number_of_current_jobs(num)
      self.set_num_workers([MiddleManagement::Config::MIN_WORKERS, [num, MiddleManagement::Config::MAX_WORKERS].min].max)
    end
    
    private
    def self.get_heroku_client
      Heroku::Client.new(MiddleManagement::Config::HEROKU_USERNAME, MiddleManagement::Config::HEROKU_PASSWORD)
    end
    
    def self.set_num_workers(num_workers)
      self.get_heroku_client.set_workers(MiddleManagement::Config::HEROKU_APP, num_workers)
    end
  end
end