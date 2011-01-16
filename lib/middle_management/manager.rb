require 'heroku'

module MiddleManagement
  class Manager
    def self.enforce_number_of_current_jobs(num)
      self.set_num_workers([ENV['MIDDLE_MANAGEMENT_MIN_WORKERS'].to_i, [num, ENV['MIDDLE_MANAGEMENT_MAX_WORKERS'].to_i].min].max)
    end
    
    private
    def self.get_heroku_client
      Heroku::Client.new(ENV['MIDDLE_MANAGEMENT_HEROKU_USERNAME'], ENV['MIDDLE_MANAGEMENT_HEROKU_PASSWORD'])
    end
    
    def self.set_num_workers(num_workers)
      self.get_heroku_client.set_workers(ENV['MIDDLE_MANAGEMENT_HEROKU_APP'], num_workers)
    end
  end
end