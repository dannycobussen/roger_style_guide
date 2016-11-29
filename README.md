# Roger Style Guide

Helpers to create styleguides.

## What's in it?

### Components

### Generator
Quick & easy component generation:

`roger generate component NAME`

will generate this structure in your components path:
```
NAME.html.erb
_NAME.html.erb
_NAME.scss
```

Options for the command are:

* `--js` : Will generate a `NAME.js` file too
* `--extension=EXT` : Will generate a `_NAME.EXT` instead of `_NAME.html.erb`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'roger_styleguide'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install roger_styleguide

## Contributing

1. Fork it ( https://github.com/digitpaint/roger_style_guide/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
