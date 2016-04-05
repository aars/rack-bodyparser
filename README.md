# Rack::BodyParser #

Rack middleware that provides a way to parse the request body without touching 
`params` or `request.params`. 

Instead the parser output is available through `env['parsed_body']` or 
optionally through the Rack::Request object as `request.parsed_body` and/or 
a custom attribute per parser.

Rack::BodyParser is heavily inspired by 
[Rack::Parser](https://github.com/achiu/rack-parser).

## Key Features (differences to Rack::Parser) ##

1. seperation of `params`/`request.params` and the `parsed_body`.
1. (optional) patching of `Rack::Request`:

  Access parsed payload through `request.parsed_body` with support 
  for custom `request.#{your_key_here}` per parser. 
  Enable with `:patch_request => true`.

Note: Rack::BodyParser **does** **not** contain any parsers by out of the box.

## Installation ##

`TODO`

## Usage ##

Define your parsers per content_type. 

Rack::BodyParser accepts `String` or `Regexp` keys as content_type, 
and anything that `respond_to? 'call'` as parser.

Sinatra example:

```ruby
# app.rb

use Rack::BodyParser, :parsers => { 
  'application/json' => proc { |data| JSON.parse data },
  'application/xml'  => proc { |data| XML.parse data },
  %r{msgpack}        => proc { |data| Msgpack.parse data }
}

post '/' do
  puts env['parsed_body']
end
```

### Error Handling ###

Rack::BodyParser has one default error handler that can be overridden by 
setting the 'default' handler. These works like `:parsers`. Use a `String` or 
`Regexp` as content_type key and anything that `respond_to? 'call'` as the
error handler. The error handler must accept the two parameters 
`Error` and `type` (the content type).

```ruby
use Rack::Parser, :handlers => {
  'default' => proc { |e, type| 
    [400, {}, ['[Rack::BodyParser] Failed to parse %s: %s' % [type, e.to_s]]] 
  }
}
```

Rack::BodyParsers will try to `warn` of a `logger` is present.

Note: the error handler rescues exceptions that are descents of `StandardError`. 
See http://www.mikeperham.com/2012/03/03/the-perils-of-rescue-exception/

## Patch Rack::Request ##

Setting up Rack::BodyParser with `:patch_request => true` will add
a `parsed_body` method to Rack::Request. Parsers can also provide a
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

```
## Inspirations ##

This project is heavily inspired by [Rack::Parser](https://github.com/achiu/rack-parser). I built
this because I did not want to mix `params` and the body payload. Also because Rack::Parser contains
a ['bug'](https://github.com/achiu/rack-parser/issues/15) in it's content_type keys (which are always
used as `Regexp` through `String.match` and it looks like Rack::Parser might be abandoned (very old 
open PRs)

## Copyright

Copyright © 2016 Aaron Heesakkers. 
See [MIT-LICENSE](https://github.com/aars/rack-bodyparser/blob/master/MIT-LICENSE) for details.

