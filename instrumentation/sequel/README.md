# OpenTelemetry Sequel Instrumentation

The OpenTelemetry Sequel Ruby gem is a community maintained instrumentation for [Sequel][sequel-home].

## How do I get started?

Install the gem using:

```
gem install opentelemetry-instrumentation-sequel
```

Or, if you use [bundler][bundler-home], include `opentelemetry-instrumentation-sequel` in your `Gemfile`.

## Usage

To use the instrumentation, call `use` with the name of the instrumentation:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Sequel'
end
```

Alternatively, you can also call `use_all` to install all the available instrumentation.

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

### Configuration options

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Sequel', {
    # You may optionally set a value for 'peer.service', which
    # will be included on all spans from this instrumentation:
    peer_service: 'postgres:readonly',

    # By default, this instrumentation includes the executed SQL as the `db.statement`
    # semantic attribute. Optionally, you may disable the inclusion of this attribute entirely by
    # setting this option to :omit or sanitize the attribute by setting to :obfuscate
    db_statement: :include,
  }
end
```

## Examples

An example of usage can be seen in [`example/sequel.rb`](https://github.com/open-telemetry/opentelemetry-ruby/blob/main/instrumentation/sequel/example/sequel.rb).

## How can I get involved?

The `opentelemetry-instrumentation-sequel` gem source is [on github][repo-github], along with related gems including `opentelemetry-api` and `opentelemetry-sdk`.

The OpenTelemetry Ruby gems are maintained by the OpenTelemetry-Ruby special interest group (SIG). You can get involved by joining us on our [gitter channel][ruby-gitter] or attending our weekly meeting. See the [meeting calendar][community-meetings] for dates and times. For more information on this and other language SIGs, see the OpenTelemetry [community page][ruby-sig].

## License

The `opentelemetry-instrumentation-sequel` gem is distributed under the Apache 2.0 license. See [LICENSE][license-github] for more information.

[sequel-home]: https://github.com/ged/ruby-sequel
[bundler-home]: https://bundler.io
[repo-github]: https://github.com/open-telemetry/opentelemetry-ruby
[license-github]: https://github.com/open-telemetry/opentelemetry-ruby/blob/main/LICENSE
[ruby-sig]: https://github.com/open-telemetry/community#ruby-sig
[community-meetings]: https://github.com/open-telemetry/community#community-meetings
[ruby-gitter]: https://gitter.im/open-telemetry/opentelemetry-ruby
