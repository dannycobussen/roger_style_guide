# All generators related namespace
module RogerStyleGuide::Templates::Mustache
end

require File.dirname(__FILE__) + "/mustache/mustache_template"
require File.dirname(__FILE__) + "/mustache/tilt_template"

# Tell Roger to treat .mst as generating html output
Roger::Resolver::EXTENSION_MAP["html"] << "mst"
