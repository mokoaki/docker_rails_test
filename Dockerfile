FROM ruby:2.4.1

# build-essential ubuntu用C/C++コンパイラ、Make等の標準開発ツール一式
# libpq-dev pg_config(PostgreSQL?)の為に必要？要らないかな？
# nodejs 例のアレ

# RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN apt-get update -qq && apt-get install -y build-essential nodejs

RUN mkdir /moko_test
WORKDIR /moko_test

COPY ./Gemfile ./Gemfile
COPY ./Gemfile.lock ./Gemfile.lock

RUN echo 'gem: --no-document' >> ~/.gemrc && \
    bundle config --global jobs 2 && \
    bundle install
