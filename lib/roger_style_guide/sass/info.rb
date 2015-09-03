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
    # @option optoins [String] :source Sass source, if passed will not load @path,
    #   but only use it as reference.
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

    # Flatten variables into a flat key => value
    # This tries to preserve the parent :category and :used
    # Will add name.
    def flatten_variables(variables, parent = nil)
      output = []
      variables.each do |k, v|
        key = k
        value = {}.update(v)

        # Inherit parent category and used
        if parent
          key = parent[:name] + "[#{k}]"
          value = {
            category: parent[:category],
            used: parent[:used]
          }.update(value)
        end

        value = { name: key }.update(value)

        case value[:value]
        when Hash
          output += flatten_variables(value[:value], value)
        when Array
          output += value[:value].map do |list_value|
            {
              name: key + "[]",
              category: value[:category],
              used: value[:used]
            }.update(list_value)
          end
        else
          output << value
        end
      end
      output
    end

    protected

    # Do the actual parsing of the sass file.
    def parse
      engine = Sass::Engine.new(sass_source, syntax: :scss)
      env = @environment

      tree = engine.to_tree

      # VarVisitor is a subclass of the perform visitor so
      # this does most of the SASS heavy lifting
      var_visitor = VarVisitor.new(env)
      tree = var_visitor.send(:visit, tree)

      # Store the variables
      @variables = categorize_variables(var_visitor.variables)

      Sass::Tree::Visitors::CheckNesting.visit(tree) # Check again to validate mixins
      tree, extends = Sass::Tree::Visitors::Cssize.visit(tree)
      Sass::Tree::Visitors::Extend.visit(tree, extends)

      color_visitor = ColorVisitor.new
      color_visitor.send(:visit, tree)

      # Store the colors
      @colors = color_visitor.colors

      @_parsed = true
      nil
    end

    def sass_source
      if @options[:source]
        @options[:source]
      else
        File.read(@path.to_s)
      end
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
        # First apply the filter to the value itself
        next unless apply_filter(value, filter)

        # Handle Hash and Array
        case value[:value]
        when Hash
          result = filter_variables(value[:value], filter)

          # We don't want this value to appear in our output at all if no children match
          next unless result.length > 0
        when Array
          result = value[:value].select { |list_value| apply_filter(list_value, filter) }

          # We don't want this value to appear in our output at all if no children match
          next unless result.length > 0
        else
          result = value[:value]
        end

        # Assign new value
        filtered_variables[key] = value.dup
        filtered_variables[key][:value] = result
      end

      filtered_variables
    end

    # Apply filter on type, cateogry and used count
    def apply_filter(value, filter)
      apply_filter_type(value, filter) &&
        apply_filter_category(value, filter) &&
        apply_filter_used(value, filter)
    end

    def apply_filter_type(value, filter)
      return true unless filter_applicable?(:type, value, filter)
      value[:type] == filter[:type]
    end

    def apply_filter_category(value, filter)
      return true unless filter_applicable?(:category, value, filter)
      value[:category] == filter[:category]
    end

    def apply_filter_used(value, filter)
      return true unless filter_applicable?(:used, value, filter)
      filter[:used] == true && value[:used] > 0 ||
        filter[:used] == false && value[:used] == 0
    end

    # Should we apply the filter with key key?
    def filter_applicable?(key, value, filter)
      filter.key?(key) && value.key?(key)
    end
  end
end
