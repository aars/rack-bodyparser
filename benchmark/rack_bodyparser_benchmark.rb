$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'benchmark_helper'

# Helper method providing request options.
def req_opts(content_type = 'plain/text')
  {
    input: 'body',
    'CONTENT_TYPE' => content_type
  }
end

# MockParser
module MockParser
  def self.env=(env)
    @env = env
  end

  def self.call(_body)
    'parsed body from mock parser'
  end
end

Benchmark.ips do |x|
  noop = proc { [200, {}, ['hello']] }
  middleware_opts = {
    parsers: {
      'plain/text' => proc { 'string matched parser' },
      /regexp/     => proc { 'regexp matched parser' },
      'mock'       => MockParser
    }
  }
  middleware_opts_patched = middleware_opts.clone.update(patch_request: true)

  middleware         = Rack::BodyParser.new(noop, middleware_opts)
  middleware_patched = Rack::BodyParser.new(noop, middleware_opts_patched)

  # Compare BodyParser to a simple noop request.
  noop_req           = Rack::MockRequest.new(noop)
  parser_req         = Rack::MockRequest.new(middleware)
  parser_patched_req = Rack::MockRequest.new(middleware_patched)

  # And off we go!
  x.config(time: 5, warmup: 1)
  x.report('Without BodyParser') { noop_req.post('/', req_opts) } # baseline
  # Try different setups
  x.report('No parser found') do
    parser_req.post('/', req_opts('x'))
  end
  x.report('String') do
    parser_req.post('/', req_opts)
  end
  x.report('Regexp') do
    parser_req.post('/', req_opts('regexp'))
  end
  x.report('Str, env') do
    parser_req.post('/', req_opts('mock'))
  end
  x.report('Str, patch_request') do
    parser_patched_req.post('/', req_opts)
  end
  x.compare!
end
