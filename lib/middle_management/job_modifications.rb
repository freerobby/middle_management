require 'delayed_job'
require 'delayed/backend/active_record'

class Delayed::Job < ::ActiveRecord::Base
  after_create :enforce
  after_destroy :enforce
  
  private
  def self.enforce
    MiddleManagement::Manager.enforce_number_of_current_jobs(Delayed::Job.where("run_at <= ? AND failed_at IS NULL AND locked_by IS NULL", Delayed::Backend::ActiveRecord::Job.db_time_now).count)
  end
end
