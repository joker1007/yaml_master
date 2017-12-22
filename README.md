# YamlMaster
[![Gem Version](https://badge.fury.io/rb/yaml_master.svg)](https://badge.fury.io/rb/yaml_master)
[![Build Status](https://travis-ci.org/joker1007/yaml_master.svg)](https://travis-ci.org/joker1007/yaml_master)

This gem is helper of yaml file generation from single master yaml file.
And this gem has some useful helpers. For example `!include`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'yaml_master'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yaml_master

## Usage

### command help
```
Usage: yaml_master [options]
    -m, --master=MASTER_FILE         master yaml file
    -k, --key=KEY                    single generate target key (in data: block)
    -o, --output=OUTPUT              output filename for single generate target
    -a, --all                        target all key (defined in yaml_master: block)
    -d, --dump                       dump evaluated master yaml
    -p, --properties=PROPERTIES      set property (--properties="NAME=VALUE,NAME=VALUE" or -p "NAME=VALUE" -p "NAME=VALUE")
    -v, --verbose                    verbose mode
        --version                    Print version
    -h, --help                       Prints this help
```

### Support YAML tags

| tag                            | description                                                                                   |
| ------------------------       | -------------------------------------------------------------------------------------         |
| !include {yaml_filename}       | Replace value by other yaml file content. included file can use alias in master file.         |
| !master_path                   | Replace value by master file path                                                             |
| !user_home                     | Replace value by `ENV["HOME"]`.                                                               |
| !env {key}                     | Replace value by `ENV["{key}"]`.                                                              |
| !properties {key}              | Replace value by fetched value from given properties.                                         |
| !read_file_if_exist {filename} | Replace value by content of {filename}. if {filename} does not exist, Replace value by `null` |

at first, Write master.yml

```yaml
yaml_master:
  database_yml: <%= ENV["CONFIG_DIR"] %>/database.yml
  embulk_yml: <%= ENV["CONFIG_DIR"] %>/embulk.yml

database_config: &database_config
  development: &database_development
    adapter: mysql2
    encoding: utf8
    database: development
    pool: 5
    host: &database_development_host
    username: &database_development_username root
    password: &database_development_password
    socket: /tmp/mysql.sock

  test: &database_test
    adapter: mysql2
    encoding: utf8
    database: test
    host: &database_test_host
    username: &database_test_username root
    password: &database_test_password

  production: &database_production
    adapter: mysql2
    encoding: utf8
    database: production
    pool: 5
    host: &database_production_host "192.168.1.100"
    username: &database_production_username root
    password: &database_production_password
    socket: /tmp/mysql.sock


data:
  database_yml:
    <<: *database_config

  embulk_yml:
    in:
      type: file
      path_prefix: example.csv
      parser:
        type: csv
        skip_header_lines: 1
        columns:
          - {name: key_name, type: string}
          - {name: day, type: timestamp, format: '%Y-%m-%d'}
          - {name: new_clients, type: long}

    out:
      type: mysql
      host: *database_<%= ENV["RAILS_ENV"] %>_host
      user: *database_<%= ENV["RAILS_ENV"] %>_username
      password: *database_<%= ENV["RAILS_ENV"] %>_password
      database: my_database
      table: my_table
      mode: insert

tag_sample:
  included: !include included.yml
  master_path: !master_path
  user_home: !user_home
  env: !env HOME
  properties: !properties foo
  read_file_if_exist: !read_file_if_exist sample.txt
  read_file_if_exist_nothing: !read_file_if_exist nothing.txt
```

### single output
```sh
$ RAILS_ENV=production CONFIG_DIR="." yaml_master -m master.yml -k embulk_yml -o embulk_config.yml
```

```yaml
# ./embulk_config.yml

in:
  type: file
  path_prefix: example.csv
  parser:
    type: csv
    skip_header_lines: 1
    columns:
      - {name: key_name, type: string}
      - {name: day, type: timestamp, format: '%Y-%m-%d'}
      - {name: new_clients, type: long}

out:
  type: mysql
  host: *database_<%= ENV["RAILS_ENV"] %>_host
  user: *database_<%= ENV["RAILS_ENV"] %>_username
  password: *database_<%= ENV["RAILS_ENV"] %>_password
  database: my_database
  table: my_table
  mode: insert
```

### all output
```sh
$ RAILS_ENV=production CONFIG_DIR="." yaml_master -m master.yml --all
```

outputs is following.

```yaml
# ./database.yml

---
development:
  adapter: mysql2
  encoding: utf8
  database: development
  pool: 5
  host: 
  username: root
  password: 
  socket: "/tmp/mysql.sock"
test:
  adapter: mysql2
  encoding: utf8
  database: test
  host: 
  username: root
  password: 
production:
  adapter: mysql2
  encoding: utf8
  database: production
  pool: 5
  host: 192.168.1.100
  username: root
  password: 
  socket: "/tmp/mysql.sock"
```

```yaml
# ./embulk.yml

---
in:
  type: file
  path_prefix: example.csv
  parser:
    type: csv
    skip_header_lines: 1
    columns:
    - name: key_name
      type: string
    - name: day
      type: timestamp
      format: "%Y-%m-%d"
    - name: new_clients
      type: long
out:
  type: mysql
  host: 192.168.1.100
  user: root
  password: 
  database: my_database
  table: my_table
  mode: insert
```

```yaml
# ./tag_sample.yml

---
included:
  xyz: hoge
  db:
    adapter: mysql2
    encoding: utf8
    database: development
    pool: 5
    host:
    username: root
    password:
    socket: "/tmp/mysql.sock"
  abc:
  - 1
  - 2.3
  - a: 1
    b: 2
included2:
- foo: bar
- hoge: fuga
- :abc:
  - 1
  - 2
  - 3
master_path: "/home/joker/.ghq/github.com/joker1007/yaml_master/spec/sample.yml"
master_path2: "/home/joker/.ghq/github.com/joker1007/yaml_master/spec/sample.yml"
user_home: "/home/joker"
user_home2: "/home/joker"
env: "/home/joker"
properties: '24'
read_file_if_exist: 'dummy

'
read_file_if_exist_nothing:
read_file_if_exist2: 'dummy '
```

## Raw Dump

Any yaml file can use yaml_master feature.

```yaml
# tag_sample.yml

included: !include included.yml
master_path: !master_path
user_home: !user_home
env: !env HOME
properties: !properties foo
read_file_if_exist: !read_file_if_exist sample.txt
read_file_if_exist_nothing: !read_file_if_exist nothing.txt
```

```sh
% yaml_master -m tag_sample.yml --dump
```

output

```yaml
included:
  xyz: hoge
  db:
    adapter: mysql2
    encoding: utf8
    database: development
    pool: 5
    host:
    username: root
    password:
    socket: "/tmp/mysql.sock"
  abc:
  - 1
  - 2.3
  - a: 1
    b: 2
included2:
- foo: bar
- hoge: fuga
- :abc:
  - 1
  - 2
  - 3
master_path: "/home/joker/.ghq/github.com/joker1007/yaml_master/spec/sample.yml"
master_path2: "/home/joker/.ghq/github.com/joker1007/yaml_master/spec/sample.yml"
user_home: "/home/joker"
user_home2: "/home/joker"
env: "/home/joker"
properties: '24'
read_file_if_exist: 'dummy

'
read_file_if_exist_nothing:
read_file_if_exist2: 'dummy '
```

## How to use with Docker

```sh
docker run --rm \
  -v `pwd`/:/vol \
  joker1007/yaml_master -m /vol/spec/sample.yml -k database_yml -o /vol/test.yml
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/joker1007/yaml_master.

