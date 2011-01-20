require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe MiddleManagement::Manager do
  describe "#track_creation" do
    it "increments jobs count" do
      MiddleManagement::Manager.should_receive(:current_jobs_count_last_queried).any_number_of_times.and_return(1.second.ago)
      MiddleManagement::Manager.send(:current_jobs_count=, 3)
      MiddleManagement::Manager.track_creation
      MiddleManagement::Manager.send(:current_jobs_count).should == 4
    end
  end
  
  describe "#track_completion" do
    it "decrements jobs count" do
      MiddleManagement::Manager.should_receive(:current_jobs_count_last_queried).any_number_of_times.and_return(1.second.ago)
      MiddleManagement::Manager.send(:current_jobs_count=, 3)
      MiddleManagement::Manager.track_completion
      MiddleManagement::Manager.send(:current_jobs_count).should == 2
    end
  end
  
  describe "#enforce_number_of_current_jobs" do
    before do
      stub_config(:HEROKU_APP, "test_app")
      stub_config(:MIN_WORKERS, 1)
      stub_config(:MAX_WORKERS, 10)
      stub_config(:JOBS_PER_WORKER, 1)
      @client_mock = mock("Heroku Client")
      @client_mock.should_receive(:info).any_number_of_times.and_return({:workers => 5})
      MiddleManagement::Manager.should_receive(:get_heroku_client).any_number_of_times.and_return(@client_mock)
    end
    describe "second call within 10 seconds" do
      it "delays run for 10 seconds" do
        MiddleManagement::Manager.send(:num_workers_last_set_at=, 5.seconds.ago)
        MiddleManagement::Manager.send(:current_worker_count=, 5)
        @client_mock.should_not_receive(:set_workers)
        MiddleManagement::Manager.should_receive(:current_jobs_count).any_number_of_times.and_return(6)
        delay_result = mock("Delay Object Result")
        delay_result.should_receive(:enforce_number_of_current_jobs).exactly(:once)
        MiddleManagement::Manager.should_receive(:delay).exactly(:once).and_return(delay_result)
        MiddleManagement::Manager.enforce_number_of_current_jobs
      end
    end
    describe "third call within 10 seconds" do
      it "does not create job" do
        MiddleManagement::Manager.send(:num_workers_last_set_at=, 5.seconds.ago)
        MiddleManagement::Manager.send(:current_worker_count=, 5)
        @client_mock.should_not_receive(:set_workers)
        MiddleManagement::Manager.should_receive(:current_jobs_count).any_number_of_times.and_return(6)
        MiddleManagement::Manager.should_not_receive(:delay)
        MiddleManagement::Manager.send(:last_enforcement_job_set_for=, 5.seconds.from_now)
        MiddleManagement::Manager.enforce_number_of_current_jobs
      end
    end
    describe "changes number of workers" do
      it "makes api call" do
        MiddleManagement::Manager.send(:num_workers_last_set_at=, nil)
        MiddleManagement::Manager.send(:current_worker_count=, 5)
        @client_mock.should_receive(:set_workers).exactly(:once)
        MiddleManagement::Manager.should_receive(:current_jobs_count).any_number_of_times.and_return(6)
        MiddleManagement::Manager.enforce_number_of_current_jobs
      end
    end
    describe "no change to number of workers" do
      it "does not make api call" do
        MiddleManagement::Manager.send(:num_workers_last_set_at=, nil)
        MiddleManagement::Manager.send(:current_worker_count=, 5)
        MiddleManagement::Manager.should_receive(:current_jobs_count).any_number_of_times.and_return(5)
        @client_mock.should_not_receive(:set_workers)
        MiddleManagement::Manager.enforce_number_of_current_jobs
      end
    end
  end
  
  describe "private methods" do
    describe "#current_jobs_count" do
      it "queries if hasn't queried" do
        MiddleManagement::Manager.send(:current_jobs_count=, nil)
        MiddleManagement::Manager.send(:current_jobs_count_last_queried=, nil)
        MiddleManagement::Manager.should_receive(:current_jobs_count_last_queried).any_number_of_times.and_return(nil)
        r = mock("Result")
        r.should_receive(:count).exactly(:once).and_return(3)
        Delayed::Backend::ActiveRecord::Job.should_receive(:where).exactly(:once).and_return(r)
        MiddleManagement::Manager.send(:current_jobs_count).should == 3
      end
      it "queries if last query was > 1 minute ago" do
        MiddleManagement::Manager.send(:current_jobs_count=, nil)
        MiddleManagement::Manager.send(:current_jobs_count_last_queried=, 90.seconds.ago)
        MiddleManagement::Manager.should_receive(:current_jobs_count_last_queried).any_number_of_times.and_return(nil)
        r = mock("Result")
        r.should_receive(:count).exactly(:once).and_return(3)
        Delayed::Backend::ActiveRecord::Job.should_receive(:where).exactly(:once).and_return(r)
        MiddleManagement::Manager.send(:current_jobs_count).should == 3
      end
      it "uses cache if last query was < 1 minute ago" do
        MiddleManagement::Manager.send(:current_jobs_count=, 5)
        MiddleManagement::Manager.send(:current_jobs_count_last_queried=, 59.seconds.ago)
        Delayed::Backend::ActiveRecord::Job.should_not_receive(:where)
        MiddleManagement::Manager.send(:current_jobs_count).should == 5
      end
    end
    
    describe "#calculate_needed_worker_count" do
      describe "1 job per worker" do
        before do
          stub_config(:MIN_WORKERS, 1)
          stub_config(:MAX_WORKERS, 10)
          stub_config(:JOBS_PER_WORKER, 1)
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
      describe "3 jobs per worker, MIN=0, MAX=10" do
        before do
          stub_config(:MIN_WORKERS, 0)
          stub_config(:MAX_WORKERS, 10)
          stub_config(:JOBS_PER_WORKER, 3)
        end
        it "returns 0 workers for 0 jobs" do
          MiddleManagement::Manager.send(:calculate_needed_worker_count, 0).should == 0
        end
      end
      describe "3 jobs per worker, MIN=1 MAX=10" do
        before do
          stub_config(:MIN_WORKERS, 1)
          stub_config(:MAX_WORKERS, 10)
          stub_config(:JOBS_PER_WORKER, 3)
        end
        it "returns 1 worker for 0 jobs" do
          MiddleManagement::Manager.send(:calculate_needed_worker_count, 0).should == 1
        end
        it "returns 1 worker for 1 job" do
          MiddleManagement::Manager.send(:calculate_needed_worker_count, 1).should == 1
        end
        it "returns 1 worker for 2 jobs" do
          MiddleManagement::Manager.send(:calculate_needed_worker_count, 2).should == 1
        end
        it "returns 1 worker for 3 jobs" do
          MiddleManagement::Manager.send(:calculate_needed_worker_count, 3).should == 1
        end
        it "returns 2 workers for 4 jobs" do
          MiddleManagement::Manager.send(:calculate_needed_worker_count, 4).should == 2
        end
        it "returns 2 workers for 5 jobs" do
          MiddleManagement::Manager.send(:calculate_needed_worker_count, 5).should == 2
        end
        it "returns 2 workers for 6 jobs" do
          MiddleManagement::Manager.send(:calculate_needed_worker_count, 6).should == 2
        end
        it "returns 3 workers for 7 jobs" do
          MiddleManagement::Manager.send(:calculate_needed_worker_count, 7).should == 3
        end
        it "returns 10 workers for 500 jobs" do
          MiddleManagement::Manager.send(:calculate_needed_worker_count, 500).should == 10
        end
      end
    end
    describe "#num_jobs_changes_worker_count?" do
      before do
        stub_config(:MIN_WORKERS, 1)
        stub_config(:MAX_WORKERS, 10)
        stub_config(:JOBS_PER_WORKER, 1)
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