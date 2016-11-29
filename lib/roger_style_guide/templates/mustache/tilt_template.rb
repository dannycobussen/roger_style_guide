require "tilt/template"

module RogerStyleGuide::Templates::Mustache
  # Tile template wrapper for our Mustache template
  class TiltTemplate < ::Tilt::Template
    def prepare
      @mustache = MustacheTemplate.new
    end

    def evaluate(scope, locals)
      @mustache.render(data, locals, scope)
    end
  end
end

Tilt.register RogerStyleGuide::Templates::Mustache::TiltTemplate, "mst"
