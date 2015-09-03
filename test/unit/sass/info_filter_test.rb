require "test_helper"
require File.dirname(__FILE__) + "/../../../lib/roger_style_guide/sass/info"

module RogerStyleGuide::Test::Sass
  # Test filtering of variables
  class InfoFilterTest < ::Test::Unit::TestCase
    def setup
      @scss = fixture("filter.scss")
      @info = ::RogerStyleGuide::Sass::Info.new("", nil, source: @scss)
    end

    def test_filter_category
      vars = @info.variables category: :font
      assert_equal %w(f-1 f-list f-map), vars.keys
    end

    def test_filter_category_on_map_values
      vars = @info.variables category: :font
      assert_equal %w(key list map), vars["f-map"][:value].keys
    end

    def test_filter_category_on_list_values
      vars = @info.variables category: :font
      assert_equal 2, vars["f-list"][:value].length
    end

    def test_filter_type
      vars = @info.variables type: :color
      assert_equal %w(c-1 c-list c-map), vars.keys
    end

    def test_filter_type_on_map_values
      vars = @info.variables type: :color
      assert_equal %w(key list map), vars["c-map"][:value].keys
    end

    def test_filter_type_on_list_values
      vars = @info.variables type: :color
      assert_equal 1, vars["c-list"][:value].length
    end

    def test_filter_used
      vars = @info.variables used: false
      assert_equal %w(unused-1 unused-list unused-map), vars.keys
    end

    def test_filter_used_on_map_values
      vars = @info.variables used: false
      assert_equal %w(unused), vars["unused-map"][:value].keys
    end

    def test_filter_used_on_list_values
      vars = @info.variables used: false
      assert_equal 2, vars["unused-list"][:value].length
    end
  end
end
