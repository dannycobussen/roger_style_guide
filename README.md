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

#### Helper
The `component` function is simplification of the `partial` function. Taking this directory structure:

```
html
  |- components
     |- my_component
     |  |- _my_component.html.erb
     |- other_component
        |- _other_component.html.erb
        |- _other_component_variant.html.erb
```

You can call `component('my_component', a: "b")` which will render the partial `components/my_component/_my_component.html.erb` with locals `{a: "b"}`. If you want to render another componentpartial you can also call `component('other_component/other_component_variant')`.

The base `components` path can be configured by setting `RogerStyleGuide.components_path` to a path within the HTML directory.

### Toc
The `toc` function is used to display table of contents of your Roger mockup. It's pretty simple: `toc(PATH_TO BUILD TOC FROM)`. See `toc_helper.rb` file for more info on options and lower level function.

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
