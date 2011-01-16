require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe MiddleManagement::Manager do
  describe "#enforce_number_of_current_jobs" do
    before do
      stub_config(:HEROKU_APP, "test_app")
      stub_config(:MIN_WORKERS, 1)
      stub_config(:MAX_WORKERS, 10)
      @client_mock = mock("Heroku Client")
      MiddleManagement::Manager.should_receive(:get_heroku_client).any_number_of_times.and_return(@client_mock)
    end
    describe "changes number of workers" do
      it "makes api call" do
        MiddleManagement::Manager.send(:current_worker_count=, 5)
        @client_mock.should_receive(:set_workers).exactly(:once)
        MiddleManagement::Manager.enforce_number_of_current_jobs(6)
      end
    end
    describe "no change to number of workers" do
      it "does not make api call" do
        MiddleManagement::Manager.send(:current_worker_count=, 5)
        @client_mock.should_not_receive(:set_workers)
        MiddleManagement::Manager.enforce_number_of_current_jobs(5)
      end
    end
  end
  
  describe "private methods" do
    describe "#calculate_needed_worker_count" do
      before do
        stub_config(:MIN_WORKERS, 1)
        stub_config(:MAX_WORKERS, 10)
      end
      it "returns min workers when fewer jobs than min workers" do
        MiddleManagement::Manager.send(:calculate_needed_worker_count, 0).should == 1
      end
      it "returns max workers when more jobs than max workers" do
        MiddleManagement::Manager.send(:calculate_needed_worker_count, 11).should == 10
      end
      it "returns number of jobs when job count in worker range" do
        MiddleManagement::Manager.send(:calculate_needed_worker_count, 5).should == 5
      end
    end
    describe "#num_jobs_changes_worker_count?" do
      before do
        stub_config(:MIN_WORKERS, 1)
        stub_config(:MAX_WORKERS, 10)
      end
      describe "running min workers" do
        before do
          MiddleManagement::Manager.send(:current_worker_count=, 1)
        end
        it "false to bring worker down" do
          MiddleManagement::Manager.send(:num_jobs_changes_worker_count?, 0).should == false
        end
        it "true to bring worker up" do
          MiddleManagement::Manager.send(:num_jobs_changes_worker_count?, 2).should == true
        end
        it "false to keep worker count" do
          MiddleManagement::Manager.send(:num_jobs_changes_worker_count?, 1).should == false
        end
      end
      describe "running max workers" do
        before do
          MiddleManagement::Manager.send(:current_worker_count=, 10)
        end
        it "true to bring worker down" do
          MiddleManagement::Manager.send(:num_jobs_changes_worker_count?, 9).should == true
        end
        it "false to bring worker up" do
          MiddleManagement::Manager.send(:num_jobs_changes_worker_count?, 11).should == false
        end
        it "false to keep worker count" do
          MiddleManagement::Manager.send(:num_jobs_changes_worker_count?, 10).should == false
        end
      end
      describe "num workers in middle of range" do
        before do
          MiddleManagement::Manager.send(:current_worker_count=, 5)
        end
        it "true to bring worker down" do
          MiddleManagement::Manager.send(:num_jobs_changes_worker_count?, 4).should == true
        end
        it "true to bring worker up" do
          MiddleManagement::Manager.send(:num_jobs_changes_worker_count?, 6).should == true
        end
        it "false to keep worker count" do
          MiddleManagement::Manager.send(:num_jobs_changes_worker_count?, 5).should == false
        end
      end
      describe "current_worker_count not set" do
        before do
          MiddleManagement::Manager.send(:current_worker_count=, nil)
        end
        it "true when setting to number" do
          MiddleManagement::Manager.send(:num_jobs_changes_worker_count?, 1).should == true
        end
        it "false when setting to nil" do
          MiddleManagement::Manager.send(:num_jobs_changes_worker_count?, nil).should == false
        end
      end
    end
    
    describe "#get_heroku_client" do
      it "instantiates a heroku client using environment variables" do
        stub_config(:HEROKU_USERNAME, "test_user")
        stub_config(:HEROKU_PASSWORD, "test_pass")
        Heroku::Client.should_receive(:new).with("test_user", "test_pass").exactly(:once)
        MiddleManagement::Manager.send(:get_heroku_client)
      end
    end
    
    describe "#set_num_workers" do
      it "sets the specified number of workers" do
        client_mock = mock("Heroku Client")
        MiddleManagement::Manager.should_receive(:get_heroku_client).and_return(client_mock)
        stub_config(:HEROKU_APP, "test_app")
        client_mock.should_receive(:set_workers).with("test_app", 3).exactly(:once)
        MiddleManagement::Manager.send(:set_num_workers, 3)
      end
    end
  end
end