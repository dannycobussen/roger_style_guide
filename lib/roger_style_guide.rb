require "pathname"

# Toplevel module for all things concerning RogerStyleGuide
module RogerStyleGuide
  # The path within project.html_path where the components reside
  def self.components_path=(path)
    @components_path = Pathname.new(path)
  end

  def self.components_path
    @components_path || "components"
  end
end

# Helpers
require File.dirname(__FILE__) + "/roger_style_guide/helpers"

# Generators
require File.dirname(__FILE__) + "/roger_style_guide/generators"

# Templates
require File.dirname(__FILE__) + "/roger_style_guide/templates"
