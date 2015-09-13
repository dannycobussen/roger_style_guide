require "test_helper"
require File.dirname(__FILE__) + "/../../../lib/roger_style_guide/sass/info"

module RogerStyleGuide::Test::Sass
  # Test parsing of variables
  class InfoParseVariablesTest < ::Test::Unit::TestCase
    def test_multiple_variables
      variables = parse_variables("$var1: a; $var2: b")
      assert_equal 2, variables.length
      assert variables.key?("var1")
      assert_equal "a", variables["var1"][:value]
      assert variables.key?("var2")
      assert_equal "b", variables["var2"][:value]
    end

    def test_string
      variables = parse_variables("$var: a;")

      assert_equal 1, variables.length
      assert variables.key?("var")

      var = variables["var"]

      assert var[:value].is_a?(String)
      assert_equal "a", var[:value]
    end

    def test_number
      variables = parse_variables("$var: 1px;")
      var = variables["var"]

      assert var[:value].is_a?(Numeric)
      assert_equal 1, var[:value]
      assert_equal "px", var[:unit]
    end

    def test_list
      variables = parse_variables("$var: a b c;")
      var = variables["var"]

      assert var[:value].is_a?(Array)
      assert_equal 3, var[:value].length
    end

    def test_map
      variables = parse_variables("$var: (key1: value1, key2: value2);")
      var = variables["var"]

      assert var[:value].is_a?(Hash)
      assert_equal 2, var[:value].length
      assert_equal "value1", var[:value]["key1"][:value]
    end

    def test_nested_map
      variables = parse_variables("$var: (key1: (subkey1: subvalue1), key2: value2);")
      var = variables["var"]

      assert var[:value]["key1"][:value].is_a?(Hash)
      assert_equal 1, var[:value]["key1"][:value].length
      assert_equal "subvalue1", var[:value]["key1"][:value]["subkey1"][:value]
    end

    def test_variable_type_color
      variables = parse_variables("$var: #fff")
      var = variables["var"]

      assert_equal :color, var[:type]
    end

    def test_variable_category
      variables = parse_variables("$c-1: #fff; $f-1: arial")

      assert_equal :color, variables["c-1"][:category]
      assert_equal :font, variables["f-1"][:category]
    end

    def test_used
      scss = "
        $used: 1px;
        $unused: 1px;

        .used{ width: $used; }
      "

      variables = parse_variables(scss)

      assert_equal 2, variables.length
      assert_equal 1, variables["used"][:used]
      assert_equal 0, variables["unused"][:used]
    end

    def parse_variables(source)
      info = ::RogerStyleGuide::Sass::Info.new("", nil, source: source)
      info.variables
    end
  end
end
