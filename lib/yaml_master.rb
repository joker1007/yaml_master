require "yaml_master/version"

require "yaml"
require "erb"
require "pathname"
require "pp"

YAML.add_domain_type(nil, "include") do |type, val|
  YAML.load_file(val)
end

class YamlMaster
  class KeyFetchError < StandardError
    def initialize(data, key)
      super("cannot fetch key \"#{key}\" from\n#{data.pretty_inspect}")
    end
  end
  attr_reader :master, :master_path, :properties

  def initialize(io_or_filename, property_strings = [])
    @context = Context.new(io_or_filename, PropertyParser.parse_properties(property_strings))

    @master = YAML.load(@context.render_master)
    raise "yaml_master key is necessary on toplevel" unless @master["yaml_master"]
    raise "data key is necessary on toplevel" unless @master["data"]
  end

  def generate(key, output = nil, options = {})
    puts "gen: #{output}" if options[:verbose]
    yaml = YAML.dump(fetch_data_from_master(key))

    return yaml unless output

    File.open(output, 'w') do |f|
      f.write(yaml)
    end
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

    def initialize(io_or_master_file, properties)
      case io_or_master_file
      when String
        @master_path = Pathname(io_or_master_file)
      when File
        @master_path = Pathname(io_or_master_file.absolute_path)
      end
      @properties = properties
    end

    def user_home
      Pathname(ENV["HOME"])
    end

    def read_file_if_exist(path)
      return nil unless File.exist?(path)
      File.read(path)
    end

    def include_yaml(filename)
      YAML.dump(
        YAML.load(render_yaml(File.expand_path(filename, File.dirname(@master_path)))),
        canonical: true
      ).each_line.drop(1).join
    end

    def render_master
      render_yaml(@master_path)
    end

    private

    def render_yaml(io_or_filename)
      if io_or_filename.respond_to?(:read)
        ERB.new(io_or_filename.read).result(binding)
      else
        ERB.new(File.read(io_or_filename)).result(binding)
      end
    end
  end
end
