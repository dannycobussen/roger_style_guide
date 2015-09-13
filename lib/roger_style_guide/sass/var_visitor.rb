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
    attr_reader :variables
    public :visit

    def initialize(environment)
      super(environment)
      @variables = {}
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

    protected

    def top_level_env?(env)
      !(env.parent.respond_to?(:parent) && env.parent.parent.respond_to?(:parent))
    end

    def find_variable_use_recursive(values)
      values.each do |child|
        case child
        when Sass::Script::Tree::Variable
          mark_variable_as_used(child)
        else
          find_variable_use_recursive(child.children)
        end
      end
    end

    def mark_variable_as_used(var)
      @variables[var.name] ||= {}

      if @variables[var.name].key?(:used)
        @variables[var.name][:used] += 1
      else
        @variables[var.name][:used] = 1
      end
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
