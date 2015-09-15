module RogerStyleGuide::Sass::Css
  # Modifies a fonts hash to add css.
  # Will remove _node key from hash
  class FontCssGenerator
    def initialize(environment, options)
      @environment = environment
      @options = options

      # Internal variable cache
      @_document_root_path = @options[:document_root_path]
      @_document_root_path_regexp = Regexp.new("^" + Regexp.escape(@_document_root_path.to_s))

      @_visitor = RogerStyleGuide::Sass::InfoVisitor.new(environment)
    end

    def generate(fonts)
      fonts.each do |_, font|
        node = font.delete(:_node)
        next unless node

        font[:css] = font_face_css(node)
      end

      fonts
    end

    protected

    def font_face_css(node)
      node.children = node.children.map do |n|
        if n.is_a?(Sass::Tree::PropNode) && n.resolved_name == "src"
          n.value = rewrite_font_src_node(n.value)
        end
        n
      end

      # Must revisit node to get all data
      node = @_visitor.visit(node)

      node.css
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
      real_path.to_s.sub(@_document_root_path_regexp, "") + char.to_s + rest.to_s
    end
  end
end
