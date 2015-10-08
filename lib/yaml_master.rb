require "yaml_master/version"

require "yaml"
require "erb"

class YamlMaster
  attr_reader :master

  def initialize(io_or_filename)
    data =
      if io_or_filename.is_a?(IO)
        ERB.new(io_or_filename.read).result
      else
        ERB.new(File.read(io_or_filename)).result
      end

    @master = YAML.load(data)
    raise "yaml_master key is necessary on toplevel" unless @master["yaml_master"]
    raise "data key is necessary on toplevel" unless @master["data"]
  end

  def generate(key, output)
    output_file = File.open(output, 'w')
    YAML.dump(@master["data"][key], output_file)
    output_file.close
  end

  def generate_all
    @master["yaml_master"].each do |key, output|
      generate(key, output)
    end
  end
end
