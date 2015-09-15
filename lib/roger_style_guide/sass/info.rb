require "sass"
require File.dirname(__FILE__) + "/color_visitor"
require File.dirname(__FILE__) + "/var_visitor"

module RogerStyleGuide::Sass
  # SassInfo extracts all kind of info from a Sass file
  #
  # -  `styleinfo.colors` : A list of all used colors in the output CSS
  # -  `styleinfo.variables` : A list of variables filterable
  # -  `styleinfo.fonts` : A list of fonts
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
    # @option options [String, Pathname] :document_root_path The root_path of the webserver
    #   This path will be used to rewrite URL's if needed.
    # @option options [String] :mixin_class_prefix The prefix to use when generating mixin classes
    #   This path will be used to rewrite URL's if needed.
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
        },
        mixin_category_matchers: {
          /^t-/ => :typography
        },
        mixin_class_prefix: "mixin",
        document_root_path: nil
      }

      @options = defaults.update(options)

      root = @options[:document_root_path]
      @options[:document_root_path] = Pathname.new(root).realpath if root
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
      filter(@variables, filter)
    end

    # A list of @font-face declarations
    #
    # @return [Hash] A hash with fonts in the followin format
    #     {
    #       "fontname-fontweight" => { # Name of font + weight
    #         font_name: string, # The font name
    #         font_weight: string, # The font weight
    #         css: string # CSS you can use in the styleguide. It will try to absolutize
    #                       the src paths.
    #       }
    #     }
    def fonts
      parse unless @_parsed
      @fonts
    end

    # A list of globally defined mixins
    #
    # @return [Hash] A hash with mixins in the followin format
    #     {
    #       "MIXIN_NAME" => { # Name of the mixin
    #         category: symbol/nil, # A symbol representing mixin category
    #         has_params: true/false, # Wether or not it has arguments/splat/contents
    #         used: 0 # How many times it's used
    #         css: CSS # A generated css class that has the format "mixin_class_prefix-mixinname"
    #                    Uses @options[:mixin_class_prefix]. This will only work on mixins
    #                    that do not have params.
    #       }
    #     }
    def mixins(filter = {})
      parse unless @_parsed
      filter(@mixins, filter)
    end

    # Flattens variables into just an array of values
    # This will split out maps and lists into singular values.
    #
    # @param [Hash] variables a Variable structure
    # @return [Array] An array of variables values.
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
    # This flattening preserves the parent :category and :used
    # in lists and maps as these cannot be set on child elements
    # of list and maps.
    #
    # It will add a `:name` key to the output.
    # Maps: will get names like "varname[key][subkey]"
    # Lists: will get names like "varname[]"
    #
    def flatten_variables(variables, parent = nil)
      output = []
      variables.each do |key, value|
        value = value.dup
        value[:name] = key

        # Inherit parent :category and :used values
        # Set key with parent[:name]
        value = inherit_parent_values(value, parent) if parent

        case value[:value]
        when Hash
          output += flatten_variables(value[:value], value)
        when Array
          output += flatten_variable_list(value[:value], value)
        else
          output << value
        end
      end
      output
    end

    protected

    def inherit_parent_values(value, parent)
      value.update(
        name: parent[:name] + "[#{value[:name]}]",
        category: parent[:category],
        used: parent[:used]
      )
    end

    def flatten_variable_list(list, parent)
      list.map do |list_value|
        {
          name: parent[:name] + "[]",
          category: parent[:category],
          used: parent[:used]
        }.update(list_value)
      end
    end

    # Do the actual parsing of the sass file.
    def parse
      engine = sass_engine
      env = @environment

      tree = engine.to_tree

      # VarVisitor is a subclass of the perform visitor so
      # this does most of the SASS heavy lifting
      @var_visitor = VarVisitor.new(env)
      tree = @var_visitor.visit(tree)

      Sass::Tree::Visitors::CheckNesting.visit(tree) # Check again to validate mixins
      tree, extends = Sass::Tree::Visitors::Cssize.visit(tree)
      Sass::Tree::Visitors::Extend.visit(tree, extends)

      @color_visitor = ColorVisitor.new
      @color_visitor.visit(tree)

      store_parsed_data

      @_parsed = true
      nil
    end

    def store_parsed_data
      # Store the variables
      @variables = categorize(
        @var_visitor.variables,
        @options[:variable_category_matchers]
      )

      @mixins = categorize(
        @var_visitor.mixins,
        @options[:variable_category_matchers]
      )

      @fonts = @var_visitor.fonts

      # Store the colors
      @colors = @color_visitor.colors
    end

    def sass_engine
      if @options[:source]
        Sass::Engine.new(
          @options[:source],
          syntax: :scss,
          document_root_path: @options[:document_root_path],
          mixin_class_prefix: @options[:mixin_class_prefix]
        )
      else
        Sass::Engine.for_file(
          @path.to_s,
          document_root_path: @options[:document_root_path],
          mixin_class_prefix: @options[:mixin_class_prefix]
        )
      end
    end

    # Looks at `matchers` and categorizes the `data`
    def categorize(data, matchers)
      categorized_data = data.dup
      categorized_data.each do |key, _|
        found = matchers.find do |match, _|
          key.to_s.match(match)
        end
        if found
          categorized_data[key][:category] = found[1]
        else
          categorized_data[key][:category] = nil
        end
      end
      categorized_data
    end

    # Deep filter list of variable. This means that
    # it will look into maps/list and only return the elements that
    # match
    #
    # @param [Hash] hash Variables to filter
    # @param [Hash] filter Stuff to filter on: {type: X, category: X, used: true/false}
    #
    def filter(hash, filter)
      filtered_hash = {}

      hash.each do |key, value|
        # First apply the filter to the value itself
        next unless apply_filter(value, filter)

        # Handle Hash and Array
        case value[:value]
        when Hash
          result = filter(value[:value], filter)

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
        filtered_hash[key] = value.dup
        filtered_hash[key][:value] = result
      end

      filtered_hash
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
