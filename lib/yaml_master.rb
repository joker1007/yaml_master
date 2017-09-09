require "yaml_master/version"

require "yaml"
require "erb"
require "pathname"

require "yaml_master/yaml_tree_builder"

class YamlMaster
  class KeyFetchError < StandardError
    def initialize(data, key)
      super("cannot fetch key \"#{key}\" from\n#{data.pretty_inspect}")
    end
  end
  attr_reader :master, :master_path, :properties

  def initialize(io_or_filename, property_strings = [])
    case io_or_filename
    when String
      @master_path = Pathname(io_or_filename).expand_path
    when File
      @master_path = Pathname(io_or_filename.absolute_path)
    end

    @properties = PropertyParser.parse_properties(property_strings)
    yaml = Context.new(master_path, @properties).render_master

    parser = YAML::Parser.new
    parser.handler = YamlMaster::YAMLTreeBuilder.new(@master_path, @properties, parser)
    @tree = parser.parse(yaml).handler.root
    @master = @tree.to_ruby[0]

    raise "yaml_master key is necessary on toplevel" unless @master["yaml_master"]
    raise "data key is necessary on toplevel" unless @master["data"]
  end

  def generate(key, output = nil, options = {})
    yaml = YAML.dump(fetch_data_from_master(key))
    write_to_output(yaml, output, options[:verbose])
  end

  def dump(output = nil, options = {})
    yaml = @tree.to_yaml
    write_to_output(yaml, output, options[:verbose])
  end

  def generate_all(options = {})
    @master["yaml_master"].each do |key, output|
      generate(key, output, options)
    end
  end

  private

  def fetch_data_from_master(key)
    keys = split_key(key)
    keys.inject(@master["data"]) do |data, k|
      data.fetch(k)
    end
  rescue
    raise KeyFetchError.new(@master["data"], key)
  end

  def split_key(key)
    keys = key.split(".")
    array_pattern = /\[(\d+)\]/
    keys.map do |k|
      if k.match(array_pattern)
        Regexp.last_match[1].to_i
      else
        k
      end
    end
  end

  def write_to_output(yaml, output, verbose)
    if output && verbose
      puts <<~VERBOSE
        gen: #{output}
        #{yaml}
      VERBOSE
    end

    return yaml unless output

    File.open(output, 'w') do |f|
      f.write(yaml)
    end
  end

  module PropertyParser
    class ParseError < StandardError; end

    def self.parse_properties(property_strings_or_hash)
      if property_strings_or_hash.is_a?(Hash)
        property_strings_or_hash
      else
        property_strings_or_hash.each_with_object({}) do |str, hash|
          key, value = str.split("=")
          raise ParseError.new("#{str} is invalid format") unless key && value
          hash[key] = value
        end
      end
    end
  end

  class Context
    attr_reader :master_path, :properties

    def initialize(master_path, properties)
      @master_path = master_path
      @properties = properties
    end

    def user_home
      Pathname(ENV["HOME"])
    end

    def read_file_if_exist(path)
      return nil unless File.exist?(path)
      File.read(path)
    end

    def render_master
      ERB.new(File.read(@master_path)).result(binding)
    end
  end
end
