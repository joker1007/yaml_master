FROM ruby:2.3-alpine

RUN gem install yaml_master --no-document

ENTRYPOINT ["yaml_master"]
