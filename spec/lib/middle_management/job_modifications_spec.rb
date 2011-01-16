require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe Delayed::Backend::ActiveRecord::Job do
  before do
    @client_mock = mock("Heroku Client")
    MiddleManagement::Manager.should_receive(:get_heroku_client).any_number_of_times.and_return(@client_mock)
  end
  
  describe "#new" do
    it "micromanages remaining jobs" do
      new_job = mock("New Job")
      ready_to_run_jobs_mock = mock("Ready to Run")
      Delayed::Backend::ActiveRecord::Job.should_receive(:new_without_micromanagement).exactly(:once).and_return(new_job)
      Delayed::Backend::ActiveRecord::Job.should_receive(:ready_to_run).any_number_of_times.and_return(ready_to_run_jobs_mock)
      ready_to_run_jobs_mock.should_receive(:count).any_number_of_times.and_return(3)
      MiddleManagement::Manager.should_receive(:enforce_number_of_current_jobs).with(3).exactly(:once)
      Delayed::Backend::ActiveRecord::Job.new
    end
  end
  describe "#destroy" do
    before do
      class Delayed::Backend::ActiveRecord::Job < ::ActiveRecord::Base
        def initialize; end
      end
    end
    it "micromanages remaining jobs" do
      Delayed::Backend::ActiveRecord::Job.should_receive(:new).and_return(Delayed::Backend::ActiveRecord::Job.new_without_micromanagement)
      job = Delayed::Backend::ActiveRecord::Job.new
      
      job.should_receive(:destroy_without_micromanagement).exactly(:once)
      ready_to_run_jobs_mock = mock("Ready to Run")
      Delayed::Backend::ActiveRecord::Job.should_receive(:ready_to_run).any_number_of_times.and_return(ready_to_run_jobs_mock)
      ready_to_run_jobs_mock.should_receive(:count).any_number_of_times.and_return(2)
      MiddleManagement::Manager.should_receive(:enforce_number_of_current_jobs).with(2).exactly(:once)
      job.destroy
    end
  end
end
