# Compent helper and friends
module RogerStyleGuide::Helpers::ComponentHelper
  # Ease use of components by wrapping the partial helper
  #
  # This allows us to call component("map") which will render
  # RogerStyleGuide.components_path/map/_map.html.erb
  #
  # Calling component("map/map") will still work
  #
  # Also simplifies passing of locals. It's just the second parameter of
  # the component helper.
  def component(path, locals = {}, &block)
    partial_path = component_template_paths(path).find do |template_path|
      renderer.send(:find_partial, template_path)
    end

    renderer.send(:template_not_found!, :component, path) unless partial_path

    # Render the partial
    partial(partial_path, locals: locals, &block)
  end

  def component_template_paths(path)
    name = File.basename(path)
    local_name = name.sub(/\A_?/, "_")
    extension = File.extname(name)[1..-1]
    name_without_extension = extension ? name.sub(/\.#{Regexp.escape(extension)}\Z/, "") : name

    dir = File.join(
      RogerStyleGuide.components_path,
      path.slice(0, path.size - name.size).to_s.strip
    )

    [
      # component_path/name/_name.xyz
      File.join(dir, name_without_extension, local_name),
      # component_path/name
      File.join(dir, name)
    ]
  end
end

Roger::Renderer.helper RogerStyleGuide::Helpers::ComponentHelper
