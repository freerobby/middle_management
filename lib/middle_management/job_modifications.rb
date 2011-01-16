require 'active_record'
require 'delayed_job'

module Delayed
  module Backend
    module ActiveRecord
      class Job < ::ActiveRecord::Base
        def self.new_with_micromanagement
          self.new_without_micromanagement
          MiddleManagement::Manager.enforce_number_of_current_jobs(self.ready_to_run.count)
        end
        class << self
          alias_method :new_without_micromanagement, :new
          alias_method :new, :new_with_micromanagement
        end
        
        def destroy_with_micromanagement
          destroy_without_micromanagement
          MiddleManagement::Manager.enforce_number_of_current_jobs(Delayed::Backend::ActiveRecord::Job.ready_to_run.count)
        end
        alias_method :destroy_without_micromanagement, :destroy
        alias_method :destroy, :destroy_with_micromanagement
      end
    end
  end
end
