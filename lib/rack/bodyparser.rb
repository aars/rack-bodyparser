module Rack
  # BodyParser implementation.
  class BodyParser
    # Where to get input.
    REQUEST_BODY     = 'rack.input'.freeze
    # Where to store in env
    RACK_ENV_KEY     = 'parsed_body'.freeze
    # Where to store in Rack::Request in case of options[:patch_request]
    RACK_REQUEST_KEY = 'parsed_body'.freeze

    # Default error handler
    ERROR_MESSAGE = "[Rack::BodyParser] Failed to parse %s: %s\n".freeze

    ERROR_HANDLER = proc do |e, type|
      [400, {}, format(ERROR_MESSAGE, type, e.to_s)]
    end

    attr_reader :parsers, :handlers, :logger

    def initialize(app, options = {})
      @app      = app
      @parsers  = options.delete(:parsers)  || {}
      @handlers = options.delete(:handlers) || {}
      @handlers = { 'default' => ERROR_HANDLER }.merge(@handlers)
      @logger   = options.delete(:logger)
      @options  = options
    end

    def call(env)
      type   = Rack::Request.new(env).media_type
      parser = type && detect(parsers, type)
      body   = parser && env[REQUEST_BODY].read; env[REQUEST_BODY].rewind
      if body && !body.empty?
        parser = parser.last
        begin
          parsed = parser.call body
          env.update RACK_ENV_KEY => parsed
          patch_rack_request parser, parsed if @options[:patch_request]
        rescue StandardError => e
          warn! e, type
          handler = (detect(handlers, type) || detect(handlers, 'default')).last
          return handler.call e, type
        end
      end
      @app.call env
    end

    def patch_rack_request(parser, parsed)
      return unless parser.respond_to?(:rack_request_key)
      Rack::Request.send(:define_method, parser.rack_request_key) { parsed }
    end

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
