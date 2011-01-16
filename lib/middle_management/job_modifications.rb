require 'active_record'
require 'delayed_job'
require 'delayed/backend/active_record'

module Delayed
  module Backend
    module ActiveRecord
      class Job < ::ActiveRecord::Base
        after_create {Delayed::Backend::ActiveRecord::Job.send(:enforce)}
        after_destroy {Delayed::Backend::ActiveRecord::Job.send(:enforce)}

        private
        def self.enforce
          MiddleManagement::Manager.enforce_number_of_current_jobs(Delayed::Backend::ActiveRecord::Job.where("run_at <= ? AND failed_at IS NULL AND locked_by IS NULL", Delayed::Backend::ActiveRecord::Job.db_time_now).count)
        end
      end
    end
  end
end