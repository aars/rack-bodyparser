module Rack
  # BodyParser implementation.
  class BodyParser
    # Where to get input.
    REQUEST_BODY     = 'rack.input'.freeze
    # Where to store in env
    RACK_ENV_KEY     = 'parsed_body'.freeze
    # Where to store in Rack::Request in case of opts[:patch_request]
    RACK_REQUEST_KEY = 'parsed_body'.freeze

    # Default error handler
    ERROR_MESSAGE = "[Rack::BodyParser] Failed to parse %s: %s\n".freeze

    ERROR_HANDLER = proc do |e, type|
      [400, {}, format(ERROR_MESSAGE, type, e.to_s)]
    end

    HANDLERS = { 'default' => ERROR_HANDLER }.freeze

    attr_reader :parsers, :handlers, :logger

    def initialize(app, opts = {})
      @app      = app
      @parsers  = opts.delete(:parsers) || {}
      @handlers = HANDLERS.merge(opts.delete(:handlers) || {})
      @logger   = opts.delete(:logger)
      @opts     = opts
    end

    def call(env)
      type   = Rack::Request.new(env).media_type
      parser = type && detect(parsers, type)

      if parser
        begin
          parse_with(parser.last, env) # parser.last is actual parser
        rescue StandardError => e
          return handle_error(e, type) # return error response
        end
      end

      # return control to app
      @app.call env
    end

    def request_body(env)
      body = env[REQUEST_BODY].read
      env[REQUEST_BODY].rewind

      body
    end

    def parse_with(parser, env)
      body = request_body(env)
      return unless body && !body.empty?

      # parse!
      parsed = parser.call(body)

      # store results in env, optionally in Rack::Request.
      env.update(RACK_ENV_KEY => parsed)
      patch_rack_request(parser, parsed) if @opts[:patch_request]
    end

    def handle_error(e, type)
      warn!(e, type)
      handler = (detect(handlers, type) || detect(handlers, 'default')).last
      handler.call(e, type)
    end

    def patch_rack_request(parser, parsed)
      return unless parser.respond_to?(:rack_request_key)
      Rack::Request.send(:define_method, parser.rack_request_key) { parsed }
    end

    # returns [type, parser]
    def detect(hash, what)
      hash.detect do |match, _|
        match.is_a?(Regexp) ? what.match(match) : what.eql?(match)
      end
    end

    def warn!(e, type)
      return unless logger
      logger.warn format(ERROR_MESSAGE, type, e.to_s)
    end
  end
end
