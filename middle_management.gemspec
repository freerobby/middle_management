# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "middle_management/version"

Gem::Specification.new do |s|
  s.name        = "middle_management"
  s.version     = MiddleManagement::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Robby Grossman"]
  s.email       = ["robby@freerobby.com"]
  s.homepage    = "http://github.com/freerobby/middle_management"
  s.summary     = %q{Delayed Job worker management for Heroku.}
  s.description = %q{Middle Management hires and fires your delayed_job workers automatically so that you get all of your work done quickly for as little money as possible.}
  
  s.add_development_dependency "rspec", ">= 2.4.0"

  s.rubyforge_project = "middle_management"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
