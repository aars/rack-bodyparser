$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'benchmark_helper'

# Helper method providing request options.
def req_opts(content_type = 'plain/text')
  {
    input: 'body',
    'CONTENT_TYPE' => content_type
  }
end

Benchmark.ips do |x|
  noop = proc { [200, {}, ['hello']] }
  middleware_opts = {
    parsers: {
      'plain/text' => proc { 'parsed body' },
      /regexp/     => proc { 'regexp matched parser' }
    }
  }
  middleware = Rack::BodyParser.new(noop, middleware_opts)

  # Compare BodyParser to a simple noop request.
  parser_req = Rack::MockRequest.new(middleware)
  noop_req   = Rack::MockRequest.new(noop)

  # And off we go!
  x.config(time: 10, warmup: 10)
  x.report('noop')           { noop_req.post('/', req_opts) }
  x.report('No match')       { parser_req.post('/', req_opts('x')) }
  x.report('Match (string)') { parser_req.post('/', req_opts) }
  x.report('Match (regexp)') { parser_req.post('/', req_opts('regexp')) }
  x.compare!
end
