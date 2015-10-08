require 'spec_helper'

RSpec.describe YamlMaster do
  let!(:yaml_master) { YamlMaster.new(File.expand_path("../sample.yml", __FILE__)) }

  it "#generate_all" do
    FakeFS.activate!

    expect(File.exist?("./database.yml")).to be_falsey
    yaml_master.generate_all
    expect(File.exist?("./database.yml")).to be_truthy

    config = YAML.load_file("./database.yml")
    expect(config["development"]["adapter"]).to eq "mysql2"
    expect(config["test"]["adapter"]).to eq "mysql2"
    expect(config["production"]["adapter"]).to eq "mysql2"

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
