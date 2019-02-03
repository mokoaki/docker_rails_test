FROM ruby:2.5.3
LABEL maintainer="mokoriso@gmail.com"

ENV LANG="C.UTF-8" \
    APP_HOME="/docker_rails_test"

WORKDIR $APP_HOME

RUN apt-get update && \
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    # build-essential
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    gem update --system

RUN groupadd -r --gid 1000 rails && \
    useradd -m -r --uid 1000 --gid 1000 rails && \
    mkdir -p $APP_HOME $BUNDLE_APP_CONFIG && \
    chown -R rails:rails $APP_HOME && \
    chown -R rails:rails $BUNDLE_APP_CONFIG

# 以降はrailsユーザ権限にて実行される
USER rails

RUN gem install bundler && \
    bundle config --local jobs 4 && \
    bundle config --local path vendor/bundle
