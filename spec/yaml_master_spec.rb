require 'spec_helper'

RSpec.describe YamlMaster do
  let!(:yaml_master) { YamlMaster.new(File.expand_path("../sample.yml", __FILE__)) }

  after do
    FakeFS.deactivate!
  end

  it "#generate_all" do
    FakeFS.activate!

    expect(File.exist?("./database.yml")).to be_falsey
    yaml_master.generate_all
    expect(File.exist?("./database.yml")).to be_truthy

    yaml1 = YAML.load_file("./database.yml")
    expect(yaml1["development"]["adapter"]).to eq "mysql2"
    expect(yaml1["test"]["adapter"]).to eq "mysql2"
    expect(yaml1["production"]["adapter"]).to eq "mysql2"

    yaml2 = YAML.load_file("./embedded_methods.yml")
    expect(yaml2["master_path"]).to eq File.expand_path("../sample.yml", __FILE__)
    expect(yaml2["user_home"]).to eq ENV["HOME"]
    expect(yaml2["read_file_if_exist"]).to match /dummy/

    FakeFS.deactivate!
  end

  it "#generate" do
    FakeFS.activate!
    expect(File.exist?("./embulk.yml")).to be_falsey
    yaml_master.generate("embulk_yml", "./embulk.yml")
    expect(File.exist?("./embulk.yml")).to be_truthy

    config = YAML.load_file("./embulk.yml")
    expect(config["out"]["host"]).to eq "192.168.1.100"
    expect(config["out"]["user"]).to eq "root"
    expect(config["out"]["password"]).to be_nil

    FakeFS.deactivate!
  end
end
