FROM alpine:3.2
MAINTAINER Joseph Dayo <joseph.dayo@gmail.com>
RUN apk update
RUN apk upgrade
RUN apk add curl wget bash
# Install ruby and ruby-bundler
RUN apk add ruby ruby-bundler ruby-io-console ruby-dev build-base

# Clean APK cache
RUN rm -rf /var/cache/apk/*

WORKDIR /usr/src/app

ADD ./Gemfile /usr/src/app
ADD ./Gemfile.lock /usr/src/app
RUN bundle
ADD ./ /usr/src/app
EXPOSE 9292
CMD ["bundle", "exec", "puma", "config.ru"]
