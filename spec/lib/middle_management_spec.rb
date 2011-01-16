require 'middle_management'

describe MiddleManagement do
  it "executes test()" do
    MiddleManagement::TestClass.test.should == "pass!"
  end
end