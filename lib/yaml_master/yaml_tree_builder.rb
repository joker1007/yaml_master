# frozen_string_literal: false
require 'yaml'
require 'pathname'

class YamlMaster::YAMLTreeBuilder < YAML::TreeBuilder
  def initialize(master_path, properties, parser)
    super()
    @master_path = master_path
    @properties = properties
    @parser = parser
  end

  def scalar(value, anchor, tag, plain, quoted, style)
    case tag
    when "!include"
      ensure_tag_argument(tag, value)

      path = Pathname(value)
      path = path.absolute? ? path : @master_path.dirname.join(path)
      tree = YAML.parse(File.read(path))
      @last.children << tree.children[0]
    when "!master_path"
      s = build_scalar_node(@master_path.to_s)
      @last.children << s
      s
    when "!fullpath"
      path = Pathname(value)
      path = path.absolute? ? path : @master_path.dirname.join(path)
      s = build_scalar_node(path.to_s)
      @last.children << s
      s
    when "!user_home"
      s = build_scalar_node(ENV["HOME"])
      @last.children << s
      s
    when "!properties"
      ensure_tag_argument(tag, value)

      s = build_scalar_node(@properties[value])
      @last.children << s
      s
    when "!env"
      ensure_tag_argument(tag, value)

      s = build_scalar_node(ENV[value])
      @last.children << s
      s
    when "!read_file_if_exist"
      ensure_tag_argument(tag, value)

      path = Pathname(value)
      path = path.absolute? ? path : @master_path.dirname.join(path)
      content = path.file? && path.readable? ? File.read(path) : nil
      s = build_scalar_node(content, false, true, 4)
      @last.children << s
      s
    else
      super
    end
  end

  private

  def ensure_tag_argument(tag, value)
    if value.empty?
      mark = @parser.mark
      $stderr.puts "tag format error"
      $stderr.puts "#{tag} requires 1 argument at #{mark.line}:#{mark.column}"
      exit 1
    end
  end

  def build_scalar_node(value, plain = true, quoted = true, style = 1)
    if value
      YAML::Nodes::Scalar.new(value, nil, nil, plain, quoted, style)
    else
      YAML::Nodes::Scalar.new("null", nil, nil, true, false, 1)
    end
  end
end
