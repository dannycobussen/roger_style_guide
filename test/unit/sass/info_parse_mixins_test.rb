require "test_helper"
require File.dirname(__FILE__) + "/../../../lib/roger_style_guide/sass/info"

module RogerStyleGuide::Test::Sass
  # Test parsing of variables
  class InfoParseMixinsTest < ::Test::Unit::TestCase
    def test_mixin_without_params
      mixins = parse_mixins("@mixin test { }")
      assert_equal 1, mixins.length
      assert mixins.key?("test")
      assert_equal false, mixins["test"][:has_params]
    end

    def test_mixin_with_params
      mixins = parse_mixins("@mixin test($param) { }")
      assert_equal 1, mixins.length
      assert mixins.key?("test")
      assert_equal true, mixins["test"][:has_params]
    end

    def test_mixin_use
      scss = "
        @mixin used {}
        @mixin unused {}

        @include used;

        .used {
          @include used;
        }
      "

      mixins = parse_mixins(scss)

      assert_equal 2, mixins.length
      assert_equal 2, mixins["used"][:used]
      assert_equal 0, mixins["unused"][:used]
    end

    def test_mixin_css
      mixins = parse_mixins("@mixin test { font-weight: bold; }")
      mixin = mixins["test"]

      assert mixin[:css].is_a? String
      assert mixin[:css].include?(".mixin-test")
      assert mixin[:css].include?("font-weight: bold;")
    end

    def parse_mixins(source)
      info = ::RogerStyleGuide::Sass::Info.new("", nil, source: source)
      info.mixins
    end
  end
end
