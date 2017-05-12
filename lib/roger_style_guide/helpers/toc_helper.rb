# Methods for generating Table of Contents
module RogerStyleGuide::Helpers::TocHelper
  # rubocop:disable Metrics/MethodLength,
  # rubocop:disable Metrics/CyclomaticComplexity,
  # rubocop:disable Metrics/PerceivedComplexity,
  # rubocop:disable Metrics/AbcSize

  DEFAULT_MATCH = /html.erb\Z/
  DEFAULT_MAX_DEPTH = 1000
  DEFAULT_LINKER = lambda do |url, name, level|
    "<a href='#{url}' class='level-#{level}' target='fbody'>#{name}</a>"
  end

  # Generate a table of contents for a certain path getting all files
  # that match the `match` regexp and go `max_depth` levels deep.
  #
  # Options are:
  #
  # - match [Regexp] (/html.erb\Z/) What files to match
  # - max_depth [Integer] (1000) How many directory levels deep should we go
  # - linker [lambda {|url, name| ... }] A lambda writing out the <a .. > tag.
  #
  # Will output html in this structure:
  #
  # ```
  # <ul class="level-0">
  #   <li>
  #     <span class='title-0'>Name</span>
  #     <ul class="level-1">
  #       <li><a href='URL'>NAME</a>
  #     </ul>
  #   </li>
  # </ul>
  # ```
  def toc(path = nil, options = {})
    options = {
      match: DEFAULT_MATCH,
      max_depth: DEFAULT_MAX_DEPTH,
      linker: DEFAULT_LINKER
    }.update(options)

    path ||= env["roger.project"].html_path

    tree = traverse_tree(path, options[:max_depth], options[:match])
    display_tree(tree, options)
  end

  # Path will be used to generate the real link
  # Name_path can be used to use a different string as link name
  def link_to_template(path, name = nil, level = nil, linker = DEFAULT_LINKER)
    # Strip of html path
    url = path.to_s.gsub(env["roger.project"].html_path.to_s, "").gsub(/html\.erb$/, "html")
    name ||= humanize_path(path)

    linker.call(url, name, level)
  end

  # Convert path into human readable name
  def humanize_path(path)
    File.basename(path).split(".", 2).first.capitalize
  end

  # Build a tree
  #
  # - Path: The path to get the entries from
  # - Match: Files to match (use regexp). Will only match the File.basename
  # - Max_depth: How deep should we traverse the tree?
  # - Level: keep track of how deep we are in the recursino
  #
  # @return result = {name: "XX", path: "XX", children: [], type: :file}
  def traverse_tree(path, max_depth = DFEAULT_MAX_DEPTH, match = DEFAULT_MATCH, level = 0)
    result = { name: humanize_path(path), path: path, children: [], type: :dir }
    path = Pathname.new(path)

    # Don't go deeper if we reached max_depth
    return if level >= max_depth

    path.entries.sort.each do |entry|
      entry_path = path + entry

      # Normalize paths, removing all "." and "_" files
      next if entry.to_s.start_with?(".") || entry.to_s.start_with?("_")

      # Check match
      next if entry_path.file? && !entry.to_s.match(match)

      if entry_path.directory?
        subdir = traverse_tree(entry_path, max_depth, match, level + 1)

        result[:children] << subdir if subdir
      else
        result[:children] << { name: humanize_path(entry), path: path + entry, type: :file }
      end
    end

    # If we don't have children we're not going to be visible.
    return if result[:children].empty?

    result
  end

  # Display the tree
  #
  # @option :linker The linker to use
  def display_tree(tree, options = {}, level = 0)
    return "" unless tree

    linker = options[:linker] || DEFAULT_LINKER

    output = []
    output << "<ul class='level-#{level}'>"

    tree[:children].each do |entry|
      output << "<li>"
      if entry[:type] == :file
        output << link_to_template(entry[:path], entry[:name], level, linker)
      else
        if entry[:children].length == 1 &&
           entry[:children][0][:type] == :file &&
           entry[:children][0][:name] == entry[:name]
          output << link_to_template(entry[:children][0][:path], entry[:name], level, linker)
        else
          # Check if there is a file exactly named like the current entry.
          # if there is we'll pluck the file out of the child list and link
          # the directory entry directly.
          modified_entry = { children: entry[:children].dup }
          if child = entry[:children].find { |c| c[:type] == :file && c[:name] == entry[:name] }
            modified_entry[:children].delete(child)
            output << link_to_template(child[:path], entry[:name], level, linker)
          else
            output << "<span class='title-#{level}'>#{entry[:name]}</span>"
          end
          output << display_tree(modified_entry, options, level + 1)
        end
      end
      output << "</li>"
    end

    output << "</ul>"

    output.join("\n")
  end
end

Roger::Renderer.helper RogerStyleGuide::Helpers::TocHelper
