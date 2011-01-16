require 'active_record'
require 'delayed_job'
require 'delayed/backend/active_record'

module Delayed
  module Backend
    module ActiveRecord
      class Job < ::ActiveRecord::Base
        after_create do
          MiddleManagement::Manager.track_creation
          MiddleManagement::Manager.enforce_number_of_current_jobs
        end
        after_destroy do
          MiddleManagement::Manager.track_completion
          MiddleManagement::Manager.enforce_number_of_current_jobs
        end
      end
    end
  end
end