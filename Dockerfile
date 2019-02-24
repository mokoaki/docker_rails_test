FROM ruby:2.6.1

LABEL maintainer="mokoriso@gmail.com"

ARG APP_HOME="/docker_rails_test"

ENV LANG="C.UTF-8" \
  EDITOR="vim"

RUN apt-get update && \
  curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
  apt-get install -y --no-install-recommends nodejs \
  # build-essential \
  vim && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
  gem update --system

COPY ["./Gemfile", "./Gemfile.lock", "${APP_HOME}/"]

RUN groupadd -r --gid 1000 rails && \
  useradd -m -r --uid 1000 --gid 1000 rails && \
  mkdir -p $APP_HOME $BUNDLE_APP_CONFIG && \
  chown -R rails:rails $APP_HOME && \
  chown -R rails:rails $BUNDLE_APP_CONFIG

# (基本的に)以降はrailsユーザ権限にて実行される
USER rails

WORKDIR $APP_HOME

RUN gem update bundler && \
  bundle install --jobs=4

RUN echo "alias ll='ls -alG'" >> ~/.bash_aliases && \
  echo "HISTIGNORE='ll*:ls*:history*:exit'" >> ~/.bashrc && \
  echo "HISTFILE='${APP_HOME}/tmp/.bash_history'" >> ~/.bashrc
