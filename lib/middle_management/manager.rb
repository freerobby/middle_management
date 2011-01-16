require 'heroku'

module MiddleManagement
  class Manager
    
    private
    def get_heroku_client
      Heroku::Client.new(ENV['MIDDLE_MANAGEMENT_HEROKU_USERNAME'], ENV['MIDDLE_MANAGEMENT_HEROKU_PASSWORD'])
    end
    
    def set_num_workers(num_workers)
      get_heroku_client.set_workers(ENV['MIDDLE_MANAGEMENT_HEROKU_APP'], num_workers)
    end
  end
end