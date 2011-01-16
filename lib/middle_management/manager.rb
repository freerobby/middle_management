require 'heroku'
require 'delayed_job'
require 'delayed/backend/active_record'

module MiddleManagement
  class Manager
    def self.enforce_number_of_current_jobs
      if self.num_jobs_changes_worker_count?(current_jobs_count)
        if num_workers_last_set_at.nil? || num_workers_last_set_at < 10.seconds.ago
          self.set_num_workers(self.calculate_needed_worker_count(current_jobs_count))
          num_workers_last_set_at = Time.now
        else
          self.delay(:run_at => Proc.new{10.seconds.from_now}).enforce_number_of_current_jobs
        end
      end
    end
    
    def self.track_creation
      self.current_jobs_count += 1
    end
    
    def self.track_completion
      self.current_jobs_count -= 1
    end
    
    private
    cattr_accessor :num_workers_last_set_at
    cattr_accessor :current_worker_count
    cattr_writer :current_jobs_count
    cattr_accessor :current_jobs_count_last_queried
    
    def self.current_jobs_count
      if @@current_jobs_count.nil? || current_jobs_count_last_queried.nil? || current_jobs_count_last_queried < 1.minute.ago
        self.current_jobs_count = Delayed::Backend::ActiveRecord::Job.where("run_at <= ? AND failed_at IS NULL AND locked_by IS NULL", Delayed::Backend::ActiveRecord::Job.db_time_now).count
        self.current_jobs_count_last_queried = Time.now
      end
      @@current_jobs_count
    end
    
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