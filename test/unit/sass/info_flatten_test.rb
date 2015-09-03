require "test_helper"
require File.dirname(__FILE__) + "/../../../lib/roger_style_guide/sass/info"

module RogerStyleGuide::Test::Sass
  # Test Flattening of variables
  class InfoFlattenTest < ::Test::Unit::TestCase
    def info(scss)
      ::RogerStyleGuide::Sass::Info.new("", nil, source: scss)
    end

    def test_flatten_values
      info = info("$a: a; $b: b; $c: c;")
      flat = info.flatten_variable_values(info.variables)

      assert_equal %w(a b c), flat
    end

    def test_flatten_values_map
      info = info("$a: (a : a, b : b); $c: c;")
      flat = info.flatten_variable_values(info.variables)

      assert_equal %w(a b c), flat
    end

    def test_flatten_values_list
      info = info("$a: a, b; $c: c;")
      flat = info.flatten_variable_values(info.variables)

      assert_equal %w(a b c), flat
    end

    def test_flatten_variables
      info = info("$a: a; $b: b; $c: c;")
      flat = info.flatten_variables(info.variables)

      assert_equal 3, flat.length
      assert_equal %w(a b c), flat.map { |v| v[:value] }
      assert_equal %w(a b c), flat.map { |v| v[:name] }
    end

    def test_flatten_variables_map
      info = info("$a: (a : a, b : b); $c: c;")
      flat = info.flatten_variables(info.variables)

      assert_equal 3, flat.length
      assert_equal %w(a b c), flat.map { |v| v[:value] }
      assert_equal %w(a[a] a[b] c), flat.map { |v| v[:name] }
    end

    # Tests that in the flattened version the map inherts
    # :category and :used (we don't track map usage yet)
    def test_flatten_variables_map_inherits_parent_values
      info = info("$f-a: (a : (a : a), b : b); .f { font: map-get($f-a, b); }")
      flat = info.flatten_variables(info.variables)

      assert_equal [:font, :font], flat.map { |v| v[:category] }
      assert_equal [1, 1], flat.map { |v| v[:used] }
    end

    def test_flaten_variables_list
      info = info("$a: a, b; $c: c;")
      flat = info.flatten_variables(info.variables)

      assert_equal 3, flat.length
      assert_equal %w(a b c), flat.map { |v| v[:value] }
      assert_equal %w(a[] a[] c), flat.map { |v| v[:name] }
    end

    # Tests that in the flattened version the map inherts
    # :category and :used (we don't track map usage yet)
    def test_flatten_variables_list_inherits_parent_values
      info = info("$f-a: a, b; .f { font: nth($f-a, 1); }")
      flat = info.flatten_variables(info.variables)

      assert_equal [:font, :font], flat.map { |v| v[:category] }
      assert_equal [1, 1], flat.map { |v| v[:used] }
    end
  end
end
