require 'spec_helper'

RSpec.describe YamlMaster do
  let!(:yaml_master) { YamlMaster.new(File.expand_path("../sample.yml", __FILE__), ["foo=bar"]) }

  after do
    FakeFS.deactivate!
  end

  it "#generate_all" do
    FakeFS.activate!

    aggregate_failures do
      expect(File.exist?("./database.yml")).to be_falsey
      yaml_master.generate_all
      expect(File.exist?("./database.yml")).to be_truthy

      yaml1 = YAML.load_file("./database.yml")
      expect(yaml1["development"]["adapter"]).to eq "mysql2"
      expect(yaml1["test"]["adapter"]).to eq "mysql2"
      expect(yaml1["production"]["adapter"]).to eq "mysql2"

      yaml2 = YAML.load_file("./embedded_methods.yml")
      expect(yaml2["master_path"]).to eq File.expand_path("../sample.yml", __FILE__)
      expect(yaml2["master_path2"]).to eq File.expand_path("../sample.yml", __FILE__)
      expect(yaml2["user_home"]).to eq ENV["HOME"]
      expect(yaml2["user_home2"]).to eq ENV["HOME"]
      expect(yaml2["env"]).to eq ENV["HOME"]
      expect(yaml2["properties"]).to eq "bar"
      expect(yaml2["read_file_if_exist"]).to match(/dummy/)
      expect(yaml2["read_file_if_exist2"]).to match(/dummy/)
      expect(yaml2["included"]["xyz"]).to eq "hoge"
      expect(yaml2["included"]["abc"][0]).to eq 1
      expect(yaml2["included"]["db"]["database"]).to eq "development"
    end

    FakeFS.deactivate!
  end

  it "#generate" do
    FakeFS.activate!

    aggregate_failures do
      expect(File.exist?("./embulk.yml")).to be_falsey
      yaml_master.generate("embulk_yml", "./embulk.yml")
      expect(File.exist?("./embulk.yml")).to be_truthy

      config = YAML.load_file("./embulk.yml")
      expect(config["out"]["host"]).to eq "192.168.1.100"
      expect(config["out"]["user"]).to eq "root"
      expect(config["out"]["password"]).to be_nil
    end

    FakeFS.deactivate!
  end

  it "#generate (fetch nested data)" do
    config = YAML.load(yaml_master.generate("embulk_yml.in.parser.columns.[1]"))
    aggregate_failures do
      expect(config["name"]).to eq "day"
      expect(config["type"]).to eq "timestamp"
      expect(config["format"]).to eq "%Y-%m-%d"
    end
  end

  it "#generate (nothing key)" do
    aggregate_failures do
      expect { yaml_master.generate("no_data") }.to \
        raise_error(YamlMaster::KeyFetchError)
      expect { yaml_master.generate("embulk_yml.in.parser.columns.[3]") }.to \
        raise_error(YamlMaster::KeyFetchError)
    end
  end

  context "Hash style properties" do
    let!(:yaml_master) { YamlMaster.new(File.expand_path("../sample.yml", __FILE__), {"foo" => "bar"}) }

    it "#generate_all" do
      FakeFS.activate!

      yaml_master.generate_all

      yaml2 = YAML.load_file("./embedded_methods.yml")
      expect(yaml2["properties"]).to eq "bar"

      FakeFS.deactivate!
    end
  end
end
