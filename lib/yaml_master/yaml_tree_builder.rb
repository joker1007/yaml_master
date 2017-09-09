# frozen_string_literal: false
require 'yaml'
require 'pathname'

class YamlMaster::YAMLTreeBuilder < YAML::TreeBuilder
  def initialize(master_path, properties)
    super()
    @master_path = master_path
    @properties = properties
  end

  def scalar(value, anchor, tag, plain, quoted, style)
    case tag
    when "!include"
      path = Pathname(value)
      path = path.absolute? ? path : @master_path.dirname.join(path)
      tree = YAML.parse(File.read(path))
      @last.children << tree.children[0]
    when "!master_path"
      s = YAML::Nodes::Scalar.new(@master_path.to_s, nil, nil, true, false, 1)
      @last.children << s
      s
    when "!user_home"
      s = YAML::Nodes::Scalar.new(ENV.fetch("HOME", "null"), nil, nil, true, false, 1)
      @last.children << s
      s
    when "!properties"
      s = YAML::Nodes::Scalar.new(@properties.fetch(value, "null"), nil, nil, true, false, 1)
      @last.children << s
      s
    when "!env"
      s = YAML::Nodes::Scalar.new(ENV.fetch(value, "null"), nil, nil, true, false, 1)
      @last.children << s
      s
    when "!read_file_if_exist"
      path = Pathname(value)
      path = path.absolute? ? path : @master_path.dirname.join(path)
      content = path.file? && path.readable? ? File.read(path) : "null"
      s = YAML::Nodes::Scalar.new(content, nil, nil, false, true, 4)
      @last.children << s
      s
    else
      super
    end
  end
end
