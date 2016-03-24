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
  class PropertyParseError < StandardError; end

  attr_reader :master, :master_path, :properties

  def initialize(io_or_filename, property_strings = [])
    parse_properties(property_strings)

    embedded_methods_binding = EmbeddedMethods.new(self).get_binding
    data =
      if io_or_filename.is_a?(IO)
        ERB.new(io_or_filename.read).result(embedded_methods_binding)
      else
        @master_path = File.expand_path(io_or_filename)
        ERB.new(File.read(io_or_filename)).result(embedded_methods_binding)
      end

    @master = YAML.load(data)
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

  def parse_properties(property_strings)
    @properties = {}
    if property_strings.is_a?(Hash)
      @properties = property_strings
    else
      property_strings.each_with_object(@properties) do |str, hash|
        key, value = str.split("=")
        raise PropertyParseError.new("#{str} is invalid format") unless key && value
        hash[key] = value
      end
    end
  end

  class EmbeddedMethods
    def initialize(yaml_master)
      @yaml_master = yaml_master
    end

    def master_path
      Pathname(@yaml_master.master_path)
    end

    def properties
      @yaml_master.properties
    end

    def user_home
      Pathname(ENV["HOME"])
    end

    def read_file_if_exist(path)
      return nil unless File.exist?(path)
      File.read(path)
    end

    def get_binding
      binding
    end
  end
end
