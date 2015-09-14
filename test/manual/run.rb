#!/usr/bin/env ruby

require "pp"

# RogerStyleGuide
module RogerStyleGuide
end

require File.dirname(__FILE__) + "/../../lib/roger_style_guide/sass/info"

info = RogerStyleGuide::Sass::Info.new(
  File.dirname(__FILE__) + "/../fixtures/test.scss",
  nil,
  document_root_path: File.dirname(__FILE__) + "/../"
)

puts "UNUSED"
PP.pp info.variables(used: false)

puts "COLORS"
PP.pp info.variables(type: :color)

puts "MEASUREMENT"
PP.pp info.variables(category: :measurement)

# puts "ALL"
# PP.pp info.variables()

puts "------"
PP.pp info.flatten_variables info.variables(type: :color)

puts "MIXINS"

PP.pp info.mixins
puts "-" * 20
puts info.mixins_css("mokks")
PP.pp info.fonts
