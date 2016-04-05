# Rack::BodyParser #

Rack::BodyParser is Rack Middleware that provides an easy way to parse the request body without
touching `params` or `request.params` to allow full seperation of query_string parameters and
request body payload.

It is heavily inspired by [Rack::Parser](https://github.com/achiu/rack-parser).
The main difference is the seperation of `params` (and `request.params`) and the `parsed_body`.

Another difference is Rack::BodyParser has provides (optional) patching of `Rack::Request` for
easy and expressive access to the parsed body. i.e. `request.parsed_body` by default. With support
for custom `Rack::Request` attribute keys per parser.

Rack::BodyParser *does* *not* contain any parsers by out of the box.

## Installation ##

`TODO`

## Usage ##

Define your parsers per content_type. 

Rack::BodyParser accepts `String` or `Regexp` keys as content_type, and a `Proc` 
, or anything that `respond_to? 'call'` as parser.

Sinatra example:

```ruby
# app.rb

use Rack::BodyParser, :parsers => { 
  'application/json'         => proc { |data| JSON.parse data },
  'application/vnd.api+json' => proc { |data| JSON::API.parse(JSON.parse(data)) },
  'application/xml'          => proc { |data| XML.parse data },
  %r{msgpack}                => proc { |data| Msgpack.parse data }
}
```

### Error Handling ###

Rack::BodyParser has one default error handler that can be overridden by setting
the 'default' handler. These works like `:parsers`. Use a `String` or `Regexp` as
content_type key and a `Proc`, or anything that `respond_to? 'call'` as error handler.

```ruby
use Rack::Parser, :handlers => {
  'default' => proc { |e, type| 
    [400, {}, ['[Rack::BodyParser] Failed to parse %s: %s' % [type, e.to_s]]] 
  }
}
```

Rack::BodyParsers will try to `warn` of a `logger` is present.

Do note, the error handler rescues exceptions that are descents of `StandardError`. See
http://www.mikeperham.com/2012/03/03/the-perils-of-rescue-exception/


## Inspirations ##

This project is heavily inspired by [Rack::Parser](https://github.com/achiu/rack-parser). I built
this because I did not want to mix `params` and the body payload. Also because Rack::Parser contains
a ['bug'](https://github.com/achiu/rack-parser/issues/15) in it's content_type keys (which are always
used as `Regexp` through `String.match` and it looks like Rack::Parser might be abandoned (very old 
open PRs)

## Copyright

Copyright © 2016 Aaron Heesakkers. See [MIT-LICENSE](https://github.com/aars/rack-bodyparser/blob/master/MIT-LICENSE) for details.

