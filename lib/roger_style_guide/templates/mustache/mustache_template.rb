require "mustache"

module RogerStyleGuide::Templates::Mustache
  # Mustach template wrapper which handles partial
  # resolving.
  class MustacheTemplate < ::Mustache
    attr_reader :template_context

    def render(template, data, template_context = nil)
      if template_context
        @template_context = template_context
      elsif data.respond_to?(:template_context)
        @template_context = data.template_context
      end
      super(template, data)
    end

    def partial(name)
      path = @template_context.component_template_paths(name.to_s + ".mst").find do |template_path|
        result = @template_context.renderer.send(:find_partial, template_path)
        break result if result
      end

      if path
        File.read(path)
      else
        fail "No such Mustache partial found: #{name}"
      end
    end
  end
end
