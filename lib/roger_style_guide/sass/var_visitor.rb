require "pathname"

module RogerStyleGuide::Sass
  # VarVisitor
  #
  # The VarVisitor finds all variables for you and returns them
  # in the following format:
  #
  # @return [Hash] A hash with variables in the following format
  #     {
  #       "VARIABLE_NAME" => { # The variable name
  #         type: nil/:color  # A symbol representing the type (nil for value based inferable type)
  #         value: "value"/0/{}/[] # The value, if it's a map or list it will just nest
  #         unit: "px"/"em"/etc. # The unit
  #         used: 0 # How many times it's used (only at top level, not within nesting)
  #       }
  #     }
  class VarVisitor < Sass::Tree::Visitors::Perform
    public :visit, :with_environment

    attr_reader :variables, :mixins, :fonts, :root_env

    def initialize(environment)
      super(environment)
      @variables = {}
      @mixins = {}
      @fonts = {}

      @root_env = nil

      # Internal variable cache
      @_document_root_path = @environment.options[:document_root_path]
      @_document_root_path_regexp = Regexp.new("^" + Regexp.escape(@_document_root_path.to_s))
    end

    # Hack to expose the root environment
    def visit_children(parent)
      new_env = Sass::Environment.new(@environment, parent.options)

      @root_env = new_env if parent.is_a? Sass::Tree::RootNode

      with_environment new_env do
        parent.children = parent.children.map { |c| visit(c) }.flatten
        parent
      end
    end

    def visit_prop(node)
      find_variable_use_recursive([node.value])

      super(node)
    end

    def visit_variable(node)
      r = super
      env = @environment
      env = env.global_env if node.global

      # Clunky way to skip non-global definitions
      return r unless top_level_env?(env)

      value = env.var(node.name)

      store_variable(node.name.to_s, value)

      r
    end

    def visit_mixindef(node)
      r = super

      store_mixin(node)

      r
    end

    def visit_mixin(node)
      mark_as_used(@mixins, node.name)
      super(node)
    end

    def visit_directive(node)
      r = super(node)

      if node.name == "@font-face"
        fnode, data = extract_at_font_face(node)

        # We must revisit the extracted node
        # Otherwise the CSS won't work
        super(fnode)

        data[:css] = fnode.css

        puts data.inspect

        store_font(data)
      end

      r
    end

    protected

    def extract_at_font_face(node)
      fnode = node.deep_copy

      data = {
        font_family: "",
        font_weight: "regular"
      }

      fnode.children = fnode.children.map do |n|
        if n.is_a?(Sass::Tree::PropNode)
          case n.resolved_name
          when "src"
            n.value = rewrite_font_src_node(n.value)
          when "font-family"
            data[:font_family] = n.resolved_value
          when "font-weight"
            data[:font_weight] = n.resolved_value
          end
        end
        n
      end

      [fnode, data]
    end

    def rewrite_font_src_node(value)
      case value
      when Sass::Script::Tree::Funcall
        if value.name == "url"
          value = Sass::Script::Tree::Funcall.new(
            value.name,
            [
              Sass::Script::Tree::Literal.new(
                Sass::Script::Value::String.new(rewrite_path(value.args.first.value.value), :string)
              )
            ],
            value.keywords,
            value.splat,
            value.kwarg_splat
          )
        end
      when Sass::Script::Tree::ListLiteral
        value.elements.map! { |v| rewrite_font_src_node(v) }
      end
      value
    end

    def rewrite_path(path)
      # No root path defined, we can't resolve
      return path unless @_document_root_path

      # Already absolute path
      return path if path =~ %r{\A/}

      # Split to real file names
      file, char, rest = path.split(/([?#])/, 2)

      # Apparently there is no path
      return path if file.nil?

      file_base = Pathname.new(@environment.options[:original_filename]).realpath.dirname
      real_path = file_base + file

      # The file_path is not in the document_root_path
      return path unless real_path.to_s.start_with?(@_document_root_path.to_s)

      # Remove the root path from the path
      real_path.to_s.sub(@_document_root_path_regexp, "") + char + rest
    end

    def top_level_env?(env)
      env == @root_env
    end

    def find_variable_use_recursive(values)
      values.each do |child|
        case child
        when Sass::Script::Tree::Variable
          mark_as_used(@variables, child.name)
        else
          find_variable_use_recursive(child.children)
        end
      end
    end

    def mark_as_used(hash, name)
      hash[name] ||= {}

      if hash[name].key?(:used)
        hash[name][:used] += 1
      else
        hash[name][:used] = 1
      end
    end

    def store_font(data)
      key = [data[:font_family], data[:font_weight]].join("-")
      @fonts[key] ||= {}
      @fonts[key].update(data)
      @fonts
    end

    def store_mixin(node)
      key = node.name
      @mixins[key] ||= {}
      @mixins[key][:used] = 0 unless @mixins[key].key?(:used)

      if node.args.any? || node.splat || node.has_content
        @mixins[key][:has_params] = true
      else
        @mixins[key][:has_params] = false
      end
      @mixins
    end

    def store_variable(key, value)
      @variables[key] ||= {}
      @variables[key][:used] = 0 unless @variables[key].key?(:used)
      @variables[key].update(get_value(value))
      @variables
    end

    # rubocop:disable Metrics/MethodLength
    def get_value(value)
      case value
      when Sass::Script::Value::Map
        {
          value: get_map_values(value)
        }
      when Sass::Script::Value::List
        {
          value: get_list_values(value)
        }
      when Sass::Script::Value::Color
        {
          value: value.to_s,
          type: :color
        }
      when Sass::Script::Value::Number
        {
          value: value.value,
          unit: value.unit_str,
          type: :number
        }
      else
        {
          value: value.value,
          type: nil
        }
      end
    end
    # rubocop:enable Metrics/MethodLength

    def get_list_values(list)
      list.value.map do |value|
        get_value(value)
      end
    end

    def get_map_values(map)
      values = {}
      map.value.each do |k, v|
        values[k.to_s] = get_value(v)
      end
      values
    end
  end
end
