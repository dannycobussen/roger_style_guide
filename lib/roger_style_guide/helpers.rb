require "roger/template"
require File.dirname(__FILE__) + "/helpers/style_info"

# Helper class that exposes helpers to templates in Roger
module RogerStyleGuide::Helpers
  def style_info
    @_style_info ||= StyleInfo.new(env["roger.project"])
  end
end

Roger::Template.helper RogerStyleGuide::Helpers
