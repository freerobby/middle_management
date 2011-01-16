require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe Delayed::Job do
  before do
    @client_mock = mock("Heroku Client")
    MiddleManagement::Manager.should_receive(:get_heroku_client).any_number_of_times.and_return(@client_mock)
  end
  
  describe "#enforce" do
    it "micromanages remaining jobs" do
      MiddleManagement::Manager.should_receive(:enforce_number_of_current_jobs).with(3).exactly(:once)
      Delayed::Job.should_receive(:count).exactly(:once).and_return(3)
      Delayed::Backend::ActiveRecord::Job.should_receive(:db_time_now).and_return(Time.now)
      Delayed::Job.should_receive(:where).any_number_of_times.and_return(Delayed::Job)
      Delayed::Job.send(:enforce)
    end
  end
end
