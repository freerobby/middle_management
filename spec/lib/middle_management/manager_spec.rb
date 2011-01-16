require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe MiddleManagement::Manager do
  describe "#enforce_number_of_current_jobs" do
    before do
      ENV['MIDDLE_MANAGEMENT_HEROKU_APP'] = "test_app"
      ENV['MIDDLE_MANAGEMENT_MIN_WORKERS'] = '1'
      ENV['MIDDLE_MANAGEMENT_MAX_WORKERS'] = '10'
      @client_mock = mock("Heroku Client")
      MiddleManagement::Manager.should_receive(:get_heroku_client).any_number_of_times.and_return(@client_mock)
    end
    it "sets to min when fewer jobs than min" do
      @client_mock.should_receive(:set_workers).with("test_app", 1).exactly(:once)
      MiddleManagement::Manager.enforce_number_of_current_jobs(0)
    end
    it "sets to max when more jobs than max" do
      @client_mock.should_receive(:set_workers).with("test_app", 10).exactly(:once)
      MiddleManagement::Manager.enforce_number_of_current_jobs(15)
    end
    it "sets to number of jobs outstanding when in valid range" do
      @client_mock.should_receive(:set_workers).with("test_app", 5).exactly(:once)
      MiddleManagement::Manager.enforce_number_of_current_jobs(5)
    end
  end
  
  describe "private methods" do
    describe "#get_heroku_client" do
      it "instantiates a heroku client using environment variables" do
        ENV['MIDDLE_MANAGEMENT_HEROKU_USERNAME'] = "test_user"
        ENV['MIDDLE_MANAGEMENT_HEROKU_PASSWORD'] = "test_pass"
        Heroku::Client.should_receive(:new).with("test_user", "test_pass").exactly(:once)
        MiddleManagement::Manager.send(:get_heroku_client)
      end
    end
    
    describe "#set_num_workers" do
      it "sets the specified number of workers" do
        client_mock = mock("Heroku Client")
        MiddleManagement::Manager.should_receive(:get_heroku_client).and_return(client_mock)
        ENV['MIDDLE_MANAGEMENT_HEROKU_APP'] = "test_app"
        client_mock.should_receive(:set_workers).with("test_app", 3).exactly(:once)
        MiddleManagement::Manager.send(:set_num_workers, 3)
      end
    end
  end
end