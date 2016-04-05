# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'rack/bodyparser/version'

Gem::Specification.new do |s|
  s.name        = "rack-bodyparser"
  s.version     = Rack::BodyParser::VERSION
  s.authors     = ["Aaron Heesakkers"]
  s.email       = ["aaronheesakkers@gmail.com"]
  s.homepage    = "https://www.github.com/aars/rack-bodyparser"
  s.summary     = %q{Rack Middleware for parsing request body}
  s.description = %q{
    Rack Middleware for parsing request body without touching request.params.
    Allowing full seperation of query_string params and body payload.
  }

  s.rubyforge_project = "rack-bodyparser"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'rack'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rack-test'
end
