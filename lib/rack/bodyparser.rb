module Rack
  class BodyParser
    REQUEST_BODY  = 'rack.input'.freeze
    PARSED_KEY    = 'parsed_body'.freeze

    ERROR_HANDLER = proc { |err, type| [400, {}, ['']] }

    attr_reader :parsers, :handlers, :logger

    def initialize(app, options = {})
      @app      = app
      @parsers  = options.delete(:parsers)  || {}
      @handlers = options.delete(:handlers) || {}
    end

    def detect(hash, what)
      hash.detect { |match, _|
        match.is_a?(Regexp) ? what.match(match) : what.eql?(match)
      }
    end

    def call(env)
      type   = Rack::Request.new(env).media_type
      parser = type and detect(parsers, type)
      return @app.call(env) unless parser
      body = env[REQUEST_BODY].read; env[REQUEST_BODY].rewind
      return @app.call(env) unless body && !body.empty?
      begin
        parsed = parser.last.call(body)
        env.update parser.last.parsed_key || PARSED_KEY => parsed
      rescue StandardError => e
        warn! e, type
        handler = detect(handlers, type) || ['default', ERROR_HANDLER]
        return handler.last.call(e, type)
      end
    end

    def warn!(error, type)
      return unless logger
      logger.warn "[Rack::BodyParser] Error on %s : %s" % [type, error.to_s]
    end
  end
end
