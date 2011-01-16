require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe MiddleManagement::Manager do
  describe "private methods" do
    describe "#get_heroku_client" do
      it "instantiates a heroku client using environment variables" do
        manager = MiddleManagement::Manager.new
        ENV['MIDDLE_MANAGEMENT_HEROKU_USERNAME'] = "test_user"
        ENV['MIDDLE_MANAGEMENT_HEROKU_PASSWORD'] = "test_pass"
        Heroku::Client.should_receive(:new).with("test_user", "test_pass").exactly(:once)
        manager.send(:get_heroku_client)
      end
    end
    
    describe "#set_num_workers" do
      it "sets the specified number of workers" do
        client_mock = mock("Heroku Client")
        manager = MiddleManagement::Manager.new
        manager.should_receive(:get_heroku_client).and_return(client_mock)
        ENV['MIDDLE_MANAGEMENT_HEROKU_APP'] = "test_app"
        client_mock.should_receive(:set_workers).with("test_app", 3).exactly(:once)
        manager.send(:set_num_workers, 3)
      end
    end
  end
end