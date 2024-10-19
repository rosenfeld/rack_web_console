# Rack Web Console [![Build Status](https://travis-ci.org/rosenfeld/rack_web_console.svg?branch=master)](https://travis-ci.org/rosenfeld/rack_web_console)

Rack Web Console is a simple Rack app class that allows one to run arbitrary Ruby code on a given
binding, which may be useful in development mode to test some code in a given context. This is
similar to the `rails-web-console` (it was indeed extracted from it with a few enhancements) but
works for any Rack based application, including Rails.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack_web_console'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack_web_console

## Usage

The hello world is not much useful, but here you are:

```ruby
# config.ru
require 'rack_web_console'
run RackConsole.new binding
```

Usually, you'd be more interested in learning about the binding which is usually a controller
or something like that. For example, if you want to test code from inside a Roda's `route` block:

```ruby
# config.ru
require 'roda'
require 'rack_web_console'

class App < Roda
  route do |r|
    r.on('console'){ halt RackConsole.new(binding) } if ENV['RACK_ENV'] == 'development'
    'default response'
  end
end

run App
```

The local variable `r` would be available in the console for example in this case. Some
frameworks may not have a method like Roda's `halt`, so in a Rails application for example,
you may have to do this:

``` ruby
# app/controllers/console_controller.rb:
require 'rack_web_console'
class ConsoleController < ApplicationController
  skip_forgery_protection

  def index
    status, headers, body = RackConsole.new(binding).call(request.env)
    response.headers.merge! headers
    render html: body.join("\n").html_safe, status: status
  end
end

# routes.rb:
Rails.application.routes.draw do
  # ...
  match 'console' => 'console#index', via: [:get, :post] if Rails.env.development?
end
```

This example demonstrates how to use it with a Rails project, but it could be used with basically
any framework. If you're not really interested on some specific binding, you can simply mount it
directly in config.ru:

```ruby
# config.ru
require_relative 'config/environment'

require 'rack_web_console'
map('/console'){ run RackConsole.new }

run Rails.application
```

By default, only the output of the request thread is sent to the POST request response. If you
want to spawn new threads from the script and see the output of all threads, set the
`:rack_console_capture_all` thread local to true:

```ruby
Thread.current[:rack_console_capture_all] = true
Thread.start{ puts 'now it should be displayed in the browser' }.join
```

### Shortcuts from inside the textarea

- Ctrl+Enter: Run code
- Esc, Esc: Clear output

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec`
to run the tests. You can also run `bin/console` for an interactive prompt that will allow
you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a
new version, update the version number in `version.rb`, and then run `bundle exec rake
release`, which will create a git tag for the version, push git commits and tags, and
push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome [on GitHub](https://github.com/rosenfeld/rack_web_console).


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

