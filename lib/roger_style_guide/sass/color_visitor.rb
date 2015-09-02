module RogerStyleGuide::Sass
  # The ColorVisitor will visit all properties and regex match
  # for any color in the output.
  #
  # The color array can be found through the #color method
  class ColorVisitor < Sass::Tree::Visitors::Base
    def initialize
      @colors = []
    end

    def colors
      @colors.uniq
    end

    def visit_prop(node)
      return unless node.respond_to?(:resolved_value)

      @colors += find_hsla_colors(node.resolved_value)
      @colors += find_rgba_colors(node.resolved_value)
      @colors += find_hex_colors(node.resolved_value)
      @colors += find_keyword_colors(node.resolved_value)
    end

    protected

    def find_hsla_colors(str)
      colors = []

      regex = /hsla?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)/i
      str.gsub(regex) do |color|
        colors << color
      end

      colors
    end

    # Matches RGB(A)
    def find_rgba_colors(str)
      colors = []

      regex = /rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)/i
      str.gsub(regex) do |color|
        colors << color
      end

      colors
    end

    def find_hex_colors(str)
      colors = []

      # Hex 3
      str.gsub(/#[0-9a-f]{3}/i) do |color|
        colors << color
      end

      # Hex 6
      str.gsub(/#[0-9a-f]{6}/i) do |color|
        colors << color
      end

      colors
    end

    def find_keyword_colors(str)
      colors = []
      str.gsub(COLOR_REGEXP) do |color|
        colors << color
      end
      colors
    end

    COLOR_KEYWORDS = %w(
      transparent aliceblue antiquewhite aqua aquamarine azure beige
      bisque black blanchedalmond blue blueviolet brown burlywood cadetblue
      chartreuse chocolate coral cornflowerblue cornsilk crimson cyan
      darkblue darkcyan darkgoldenrod darkgray darkgreen darkgrey darkkhaki
      darkmagenta darkolivegreen darkorange darkorchid darkred darksalmon
      darkseagreen darkslateblue darkslategray darkslategrey darkturquoise
      darkviolet deeppink deepskyblue dimgray dimgrey dodgerblue firebrick
      floralwhite forestgreen fuchsia gainsboro ghostwhite gold goldenrod
      gray green greenyellow grey honeydew hotpink indianred indigo ivory
      khaki lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral
      lightcyan lightgoldenrodyellow lightgray lightgreen lightgrey lightpink
      lightsalmon lightseagreen lightskyblue lightslategray lightslategrey
      lightsteelblue lightyellow lime limegreen linen magenta maroon
      mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen
      mediumslateblue mediumspringgreen mediumturquoise mediumvioletred midnightblue
      mintcream mistyrose moccasin navajowhite navy oldlace olive olivedrab
      orange orangered orchid palegoldenrod palegreen paleturquoise
      palevioletred papayawhip peachpuff peru pink plum powderblue purple
      red rosybrown royalblue saddlebrown salmon sandybrown seagreen
      seashell sienna silver skyblue slateblue slategray slategrey snow
      springgreen steelblue tan teal thistle tomato turquoise violet
      wheat white whitesmoke yellow yellowgreen
    )

    COLOR_REGEXP = Regexp.union(COLOR_KEYWORDS)
  end
end
