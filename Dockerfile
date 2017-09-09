FROM ruby:2.4-alpine

ARG version

RUN if [[ "$version" = "" ]]; then gem install yaml_master --no-document; else gem install yaml_master --no-document --version ${version}; fi

ENTRYPOINT ["yaml_master"]
