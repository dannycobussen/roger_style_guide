module RogerStyleGuide::Generators
  # The component generator
  class ComponentGenerator < Roger::Generators::Base
    desc "Generate a new component"

    argument :name, type: :string, required: true, desc: "The component name"

    class_option(
      :components_path,
      type: :string,
      desc: "Components path, default: roger.project.html_path/#{RogerStyleGuide.components_path}"
    )

    class_option(
      :js,
      type: :boolean,
      desc: "Wether or not to generate a component js file",
      default: false
    )

    class_option(
      :extension,
      type: :string,
      desc: "The extension of the component partial",
      default: "html.erb")

    def self.source_root
      File.dirname(__FILE__) + "/component/template"
    end

    def do
      self.destination_root = components_path

      dir_options = {}
      dir_options[:exclude_pattern] = /.js\Z/ unless options[:js]

      directory(".", component_name, dir_options)
    end

    def component_name
      name
    end

    def partial_extension
      options[:extension]
    end

    def components_path
      options[:components_path] && Pathname.new(options[:components_path]) ||
        Roger::Cli::Base.project &&
          Roger::Cli::Base.project.html_path + RogerStyleGuide.components_path
    end
  end
end

Roger::Generators.register RogerStyleGuide::Generators::ComponentGenerator