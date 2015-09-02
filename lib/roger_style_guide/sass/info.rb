require "sass"
require File.dirname(__FILE__) + "/color_visitor"
require File.dirname(__FILE__) + "/var_visitor"

module RogerStyleGuide::Sass
  # SassInfo extracts all kind of info from a Sass file
  #
  # -  `styleinfo.colors` : A list of all used colors in the output CSS
  # -  `styleinfo.variables` : A list of variables filterable
  class Info
    attr_reader :path, :environment

    # Constructor
    #
    # @param [String,Pathname] path Path to sass file to get info on
    # @param [Sass::Environment, nil] environment Environment to use for Sass.
    #   Will create one if nothing is passed
    # @param [Hash] options Options hash
    #
    # @option options [Hash] :variable_category_matchers Category matchers. Modify these
    #   to match your variable category scheme
    def initialize(path, environment = nil, options = {})
      @path = path
      @environment = environment || Sass::Environment.new
      @_parsed = false

      defaults = {
        variable_category_matchers: {
          /^f-/ => :font,
          /^c-/ => :color,
          /^m-/ => :measurement,
          /^b-/ => :breakpoint
        }
      }

      @options = defaults.update(options)
    end

    # An array of all used colors in properties in the sass file.
    def colors
      parse unless @_parsed
      @colors
    end

    # All variables defined in the top-level of the sass environment
    # it will not see local variables.
    #
    # @return [Hash] A hash with variables in the following format
    #     {
    #       "VARIABLE_NAME" => { # The variable name
    #         type: nil/:color  # Symbol representing the type (nil for value based inferable type)
    #         category: symbol/nil # A symbol representing variable category based on var prefix
    #         value: "value"/0/{}/[] # The value, if it's a map or list it will just nest
    #         unit: "px"/"em"/etc. # The unit
    #         used: 0 # How many times it's used
    #       }
    #     }
    def variables(filter = {})
      parse unless @_parsed
      filter_variables(@variables, filter)
    end

    # Flattens variables into just an array of values
    def flatten_variable_values(variables)
      values = []
      variables.each do |_, v|
        case v[:value]
        when Hash
          values += flatten_variable_values(v[:value])
        when Array
          values += v[:value].map { |list_value| list_value[:value] }
        else
          values << v[:value]
        end
      end
      values
    end

    protected

    # Do the actual parsing of the sass file.
    def parse
      scss = File.read(@path.to_s)
      engine = Sass::Engine.new(scss, syntax: :scss)
      env = @environment

      tree = engine.to_tree
      var_visitor = VarVisitor.new(env)
      tree = var_visitor.send(:visit, tree)
      @variables = categorize_variables(var_visitor.variables)

      Sass::Tree::Visitors::CheckNesting.visit(tree) # Check again to validate mixins
      tree, extends = Sass::Tree::Visitors::Cssize.visit(tree)
      Sass::Tree::Visitors::Extend.visit(tree, extends)

      color_visitor = ColorVisitor.new
      color_visitor.send(:visit, tree)
      @colors = color_visitor.colors

      @_parsed = true
      nil
    end

    # Looks at options[:variable_category_matchers] and categorizes the variables
    # Only does this for top level variables, not nested maps etc.
    def categorize_variables(variables)
      categorized_variables = variables.dup
      matchers = @options[:variable_category_matchers]
      categorized_variables.each do |key, _|
        found = matchers.find do |match, _|
          key.to_s.match(match)
        end
        if found
          categorized_variables[key][:category] = found[1]
        else
          categorized_variables[key][:category] = nil
        end
      end
      categorized_variables
    end

    # Deep filter list of variable. This means that
    # it will look into maps/list and only return the elements that
    # match
    #
    # @param [Hash] variables Variables to filter
    # @param [Hash] filter Stuff to filter on: {type: X, category: X, used: true/false}
    #
    def filter_variables(variables, filter)
      filtered_variables = {}

      variables.each do |key, value|
        case value[:value]
        when Hash
          # First apply the filter to the map itself
          if apply_filter(value, filter)
            result = filter_variables(value[:value], filter)
            if result.length > 0
              filtered_variables[key] = value.dup
              filtered_variables[key][:value] = result
            end
          end
        when Array
          # First apply the filter to the list itself
          if apply_filter(value, filter)
            result = value[:value].select { |list_value| apply_filter(list_value, filter) }
            if result.length > 0
              filtered_variables[key] = value.dup
              filtered_variables[key][:value] = result
            end
          end
        else
          filtered_variables[key] = value.dup if apply_filter(value, filter)
        end
      end

      filtered_variables
    end

    # This is a very clunky way to filter. Works for now tho.
    # TODO: Needs refactoring
    def apply_filter(value, filter)
      result = true

      # Check for :type
      if filter_applicable?(:type, value, filter)
        result &&= value[:type] == filter[:type]
      end

      # Check for :category
      if filter_applicable?(:category, value, filter)
        result &&= value[:category] == filter[:category]
      end

      # Check for :used
      if filter_applicable?(:used, value, filter)
        result &&= filter[:used] == true && value[:used] > 0 ||
                   filter[:used] == false && value[:used] == 0
      end

      result
    end

    # Should we apply the filter with key key?
    def filter_applicable?(key, value, filter)
      filter.key?(key) && value.key?(key)
    end
  end
end
