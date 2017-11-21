# Rack::BodyParser #

Rack middleware for parsing incoming request body per content type.

### Inspiration ###

`Rack::BodyParser` is heavily inspired by 
[Rack::Parser](https://github.com/achiu/rack-parser), 
but behaves a bit different. See Key Features.

## Key Features; Differences to `Rack::Parser` ##

1. `Rack::BodyParser` only parses the request **body**.

1. `Rack::BodyParser` does not touch or replace the original `params` or `request.params`, and does not mix `params` and body payload. Instead the parsed result is stored in a separate key `parsed_body` in Rack's `env`.

1. (optional) patching of `Rack::Request` with support for custom getter method Parsed result available as `request.parsed_body` with support for custom `request.#{your_key_here}` per parser. Enable with `:patch_request => true`.

1. (optional) access to headers/env. If your parser `respond_to? :env=` it will be invoked with Rack's
`env` just before running `call` on your parser.

#### Batteries not included ####

`Rack::BodyParser` **does** **not** contain any parsers out of the box.

## Installation ##

Available through [RubyGems](https://rubygems.org/gems/rack-bodyparser):

`gem install rack-bodyparser`

## Usage ##

Define your `:parsers` per [`media-type`](http://www.rubydoc.info/gems/rack/Rack/Request/Helpers#media_type-instance_method), which is the `content-type` without media type parameters;
e.g., when `content-type` is `text/plain;charset=utf-8`, the media-type is `text/plain`.

Parsers configuration accepts a `String` or `Regexp` as media-type key,
and anything that `respond_to? 'call'` as parser.

Sinatra example:

```ruby
# app.rb

use Rack::BodyParser, :parsers => { 
  'application/json' => proc { |data| JSON.parse data },
  'application/xml'  => proc { |data| XML.parse data },
  /msgpack/          => proc { |data| Msgpack.parse data }
}

post '/' do
  puts env['parsed_body']
end
```

### Error Handling ###

`Rack::BodyParser` has one default error handler that can be overridden by 
setting the 'default' handler. As with parsers, you can use a `String` or
`Regexp` as media-type key and anything that `respond_to? 'call'` as the
error handler. The error handler must accept the two parameters 
`Error` and `type` (the media type).

```ruby
use Rack::Parser, :handlers => {
  'default' => proc { |e, type| 
    [400, {}, ['[Rack::BodyParser] Failed to parse %s: %s' % [type, e.to_s]]] 
  },
  'application/xml' => proc { [400, {}, 'Error: XML unsupported'] }
}
```

__Note__: the error handler rescues exceptions that descend from `StandardError`. 
See http://www.mikeperham.com/2012/03/03/the-perils-of-rescue-exception/


#### Logging ####
`Rack::BodyParser` will try to `warn` if a `logger` is present.

## Patch Rack::Request ##

Setting up `Rack::BodyParser` with `:patch_request => true` will add
a `parsed_body` getter method to `Rack::Request`. Parsers can also provide a
`:rack_request_key` to define a custom key per parser:

```ruby

# gem 'jsonapi_parser'
require 'json/api' # JSONAPI document parser/validator
module Rack::BodyParser::JSONAPI
  module Parser
    # This defines the getter key for Rack::Request
    def self.rack_request_key; :document; end

    def self.call(body)
      JSON::API.parse(JSON.parse(body))
    end
  end

  module Error
    def self.call(e, type)
      payload = {
        errors: {
          title: 'Failed to parse body as JSONAPI document',
          detail: e.message
        }
      }.to_json
      [422, {}, [payload]]
    end
  end
end

use Rack::BodyParser, :patch_request => true,
  :parsers  => { 
    'application/vnd.api+json' => Rack::BodyParser::JSONAPI::Parser
  },
  :handlers => {
    'application/vnd.api+json' => Rack::BodyParser::JSONAPI::Error
  }

post '/' do
  # These all output the same
  puts env['parsed_body']
  puts request.parsed_body
  puts request.document
end
```
## Request headers/environment ##

Need headers or other data from Rack's `env` in your parser? Set up your parser
with a setter method, `respond_to? :env=`, and it will be invoked just before running
the main `call` method.

```ruby

module ThisParserNeedsHeaders
  def self.env=(env)
    @env = env
  end

  def self.call(body)
    # @env available here for your parsing pleasure.
  end
end

use Rack::BodyParser, :parsers => { 
  'plain/text' => ThisParserNeedsHeaders 
}
```

## Copyright

`Copyright © 2016, 2017 Aaron Heesakkers.`

See [MIT-LICENSE](https://github.com/aars/rack-bodyparser/blob/master/MIT-LICENSE) for details.

