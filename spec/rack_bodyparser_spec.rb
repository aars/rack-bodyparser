require 'spec_helper'

describe Rack::BodyParser do
  let(:app) { ->(env) { [200, {}, env['PATH_INFO']] } }
  let(:request) do
    req = Rack::MockRequest.env_for('/', method: :post, input: 'plain text')
    req['CONTENT_TYPE'] = 'text/plain'
    req
  end

  context 'parsing' do
    let(:parsed_env_key) { Rack::BodyParser::RACK_ENV_KEY }

    it 'does nothing for unconfigured media-type' do
      Rack::BodyParser.new(app).call(request)
      expect(request).not_to have_key(parsed_env_key)
    end

    it 'uses the correct parser for configured media-type' do
      parsed_response = 'plain text parsed!'
      opts = {
        parsers: {
          'application/xml'  => proc { 'not me' },
          'text/plain'       => proc { parsed_response },
          'application/json' => proc { 'not me' }
        }
      }
      Rack::BodyParser.new(app, opts).call(request)

      expect(request[parsed_env_key]).to eq(parsed_response)
    end

    it 'patches the request object with a custom getter' do
      opts = {
        patch_request: true,
        parsers: {
          'text/plain' => MockParser
        }
      }
      Rack::BodyParser.new(app, opts).call(request)

      parsed_response = MockParser.call('')
      custom_getter   = MockParser.rack_request_key

      # parser was called?
      expect(request[parsed_env_key]).to eq(parsed_response)

      # Rack::Request was patched with custom getter?
      rack_request = Rack::Request.new('')
      expect(rack_request).to respond_to(custom_getter)
      expect(rack_request.send(custom_getter)).to eq(parsed_response)
    end
  end

  context 'handlers' do
    it 'responds with default' do
      err = 'it broke'
      opts = {
        parsers: { 'text/plain' => proc { raise StandardError, err } }
      }
      res = Rack::BodyParser.new(app, opts).call(request)

      # test response status code and error message
      expect(res[0]).to eq(Rack::BodyParser::ERROR_HANDLER.call[0])
      expect(res[2]).to include(err)
    end

    it 'responds with custom handler' do
      status = 422
      err = 'you broke it'
      opts = {
        parsers: { 'text/plain' => proc { raise StandardError, 'it broke' } },
        handlers: { 'text/plain' => proc { [status, {}, err] } }
      }
      res = Rack::BodyParser.new(app, opts).call(request)

      # test response status code and error message
      expect(res[0]).to eq(status)
      expect(res[2]).to include(err)
    end

    it 'can override default' do
      status = 418
      err = 'I am a teapot'
      opts = {
        parsers: { 'text/plain' => proc { raise StandardError, 'it broke' } },
        handlers: { 'default' => proc { [status, {}, err] } }
      }
      res = Rack::BodyParser.new(app, opts).call(request)

      # test response status code and error message
      expect(res[0]).to eq(status)
      expect(res[2]).to include(err)
    end
  end

  context 'logger' do
    it 'warns on error' do
      err = 'it broke'
      opts = {
        parsers: { 'text/plain' => proc { raise StandardError, err } },
        logger: MockLogger
      }

      expect(MockLogger).to receive(:warn)
      Rack::BodyParser.new(app, opts).call(request)
    end
  end
end
