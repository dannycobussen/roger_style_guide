require File.dirname(__FILE__) + "/../sass/info"

module RogerStyleGuide::Helpers
  # StyleInfo extracts all kind of info a
  # -  `styleinfo.sass_info` : Sass info about variables, etc.
  # -  `styleinfo.toc` : Creates a toc data structure
  class StyleInfo
    def initialize(project)
      @project = project
    end

    # Get sass_info from a sass file
    def sass_info(path, options = {})
      prepare_sass_load_paths!

      options = {document_root_path: @project.html_path}.update(options)

      @_sass_info ||= {}
      @_sass_info[path] ||= RogerStyleGuide::Sass::Info.new(@project.html_path + path, nil, options)
    end

    protected

    def prepare_sass_load_paths!
      return if @_prepared_sass_load_paths
      if defined? RogerSassc
        RogerSassc.load_paths.each do |path|
          Sass.load_paths << path unless Sass.load_paths.include?(path)
        end
      end
      @_prepared_sass_load_paths = true
    end
  end
end
