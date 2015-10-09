require "yaml_master/version"

require "yaml"
require "erb"
require "pathname"

class YamlMaster
  attr_reader :master, :master_path

  def initialize(io_or_filename)
    embedded_methods = EmbeddedMethods.new(self)
    embedded_methods_binding = embedded_methods.instance_eval { binding }
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

  class EmbeddedMethods
    def initialize(yaml_master)
      @yaml_master = yaml_master
    end

    def master_path
      Pathname(@yaml_master.master_path)
    end

    def user_home
      Pathname(ENV["HOME"])
    end

    def read_file_if_exist(path)
      return nil unless File.exist?(path)
      File.read(path)
    end
  end
end
