require 'heroku'

module MiddleManagement
  class Manager
    def self.enforce_number_of_current_jobs(num)
      self.set_num_workers(self.calculate_needed_worker_count(num)) if self.num_jobs_changes_worker_count?(num)
    end
    
    private
    cattr_accessor :current_worker_count
    
    def self.calculate_needed_worker_count(num_jobs)
      ideal_worker_count = num_jobs / MiddleManagement::Config::JOBS_PER_WORKER + 1
      ideal_worker_count -= 1 if num_jobs % MiddleManagement::Config::JOBS_PER_WORKER == 0
      [MiddleManagement::Config::MIN_WORKERS, [ideal_worker_count, MiddleManagement::Config::MAX_WORKERS].min].max
    end
    
    def self.num_jobs_changes_worker_count?(num_jobs)
      return false if num_jobs.nil?
      return false if self.calculate_needed_worker_count(num_jobs) == current_worker_count
      return true if current_worker_count.nil?
      # Next two lines are verified in calculate_needed_worker_count(), but let's be safe since we're dealing with real money...
      return false if self.calculate_needed_worker_count(num_jobs) < MiddleManagement::Config::MIN_WORKERS
      return false if self.calculate_needed_worker_count(num_jobs) > MiddleManagement::Config::MAX_WORKERS
      true
    end
    
    def self.get_heroku_client
      Heroku::Client.new(MiddleManagement::Config::HEROKU_USERNAME, MiddleManagement::Config::HEROKU_PASSWORD)
    end
    
    def self.set_num_workers(num_workers)
      self.get_heroku_client.set_workers(MiddleManagement::Config::HEROKU_APP, num_workers)
      current_worker_count = num_workers
    end
  end
end