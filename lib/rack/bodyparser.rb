module Rack
  class BodyParser
    # Where to get input.
    REQUEST_BODY     = 'rack.input'.freeze
    # Where to store in env
    RACK_ENV_KEY     = 'parsed_body'.freeze
    # Where to store in Rack::Request in case of options[:patch_request]
    RACK_REQUEST_KEY = 'parsed_body'.freeze
    # Default error handler
    ERROR_MESSAGE = "[Rack::BodyParser] Failed to parse %s: %s\n"
    ERROR_HANDLER = proc { |e, type|
      [400, {}, [ERROR_MESSAGE % [type, e.to_s]]]
    }

    attr_reader :app, :parsers, :handlers, :logger

    def initialize(app, options = {})
      @app           = app
      @patch_request = options.delete(:patch_request)
      @parsers       = options.delete(:parsers)  || {}
      @handlers      = options.delete(:handlers) || {}
      @handlers      = {'default' => ERROR_HANDLER}.merge(@handlers)
    end

    def call(env)
      type   = Rack::Request.new(env).media_type
      parser = type && detect(parsers, type).last
      body   = parser && env[REQUEST_BODY].read; env[REQUEST_BODY].rewind
      if body && !body.empty?
        begin
          parsed = parser.call body
          env.update RACK_ENV_KEY => parsed
          patch_rack_request parser, parsed if @patch_request
        rescue StandardError => e
          warn! e, type
          handler = (detect(handlers, type) || detect(handlers, 'default')).last
          return handler.call e, type
        end
      end
      app.call env
    end

    def patch_rack_request(parser, parsed)
      if parser.respond_to?(:rack_request_key)
        Rack::Request.send(:define_method, parser.rack_request_key) { parsed }
      end
      Rack::Request.send(:define_method, RACK_REQUEST_KEY) { parsed }
    end

    def detect(hash, what)
      hash.detect { |match, _|
        match.is_a?(Regexp) ? what.match(match) : what.eql?(match)
      }
    end

    def warn!(e, type)
      return unless logger
      logger.warn ERROR_MESSAGE % [type, e.to_s]
    end
  end
end
