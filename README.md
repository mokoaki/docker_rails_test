# dockerでRailsの開発環境テスト

## さっさとやることだけをメモ

```sh
docker-compose up -d
```

[http://localhost:3000](http://localhost:3000) にアクセス

なんかコマンド入れたかったら

```sh
docker exec -it rails bash

bin/rake db:create db:migrate
bundle install
```

こんなのも

```sh
docker-compose stop
docker-compose rm -f
```

## ここから下はどうやってやってきたかのメモ

### 構成の目標
- images
  - ruby
    - rails
  - mariadb
    - root:hogehoge
  - redis

- redis, mariadbへの接続はunix socketを使いたいけど・・まぁproductionだよね

### 参考
Quickstart: Compose and Rails
https://docs.docker.com/compose/rails/
の通りにやってみる

### アプリ名
MokoTest にしてやってみる

#### 必須ファイル
必須なファイルが4つありますとの事だが、まずはdocker-compose.ymlは放っておく
- Dockerfile
- Gemfile
- Gemfile.lock
- docker-compose.yml

#### Dockerfile
```sh
FROM ruby:2.4.1

# build-essential ubuntu用C/C++コンパイラ、Make等の標準開発ツール一式
# libpq-dev pg_config(PostgreSQL?)の為に必要？要らないかな？
# nodejs 例のアレ。

# RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN apt-get update -qq && apt-get install -y build-essential nodejs

RUN mkdir /moko_test
WORKDIR /moko_test

ADD ./Gemfile /moko_test/Gemfile
ADD ./Gemfile.lock /moko_test/Gemfile.lock

RUN bundle install

ADD . /moko_test
```

こんな感じらしい。保存する

#### Gemfile
```sh
$ bundle init
```
で作成されるrailsだけが記述されているファイルでおｋ

ちょっと編集する

```ruby
# frozen_string_literal: true
source "https://rubygems.org"

gem "rails", '5.0.1'
```

こんな感じで

#### Gemfile.lock
このファイルは Dockerfile内にてADDされるので存在はしていてほしいけど、勝手に上書きされるので存在してればおｋ

```sh
$ toush Gemfile.lock
```

タッチしとく

### dockerイメージビルドしてみる
```sh
$ docker build -t moko_test:2.4.1 .
```

### dockerイメージを確認してみる
```sh
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
moko_test           latest              a7a320c4f7a6        50 seconds ago      776MB
```

出来てるす

### moko_testコンテナを起動してみる

あたしは起動したタブで**rails s**して、他のタブから接続して操作するのが好きなので多分こんな感じ
```sh
$ docker run -it --rm --name moko_test -v "$PWD":/moko_test -p 3000:3000 moko_test:2.4.1 bash
```

### プロンプトが変わった
```sh
root@60063e5bf8e5:/myapp#
```

あー、起動したぽい

### rails new してみる
```sh
$ root@d5c9f216efb4:/moko_test# rails new . --database=mysql --skip-test-unit --skip-turbolinks
```

rails new プロジェクト名を省略して . を指定するとカレントディレクトリ名からプロジェクト名を勝手に作るらしいです　他の指定方法もあるかもしれない

Gemfileを上書きするか？と聞いてくるのでYESする

色々エラーぽいのも出た

Don't run Bundler as root. Bundler can ask for sudo if it is needed, and installing your bundle as root will break this application for all non-root users on this machine.
- rootやめろって？とりえあず無視

The dependency tzinfo-data (>= 0) will be unused by any of the platforms Bundler is installing for. Bundler is installing for ruby but the dependency is only for x86-mingw32, x86-mswin32, x64-mingw32, java. To add those platforms to the bundle, run `bundle lock --add-platform x86-mingw32 x86-mswin32 x64-mingw32 java`.
- windowsじゃなきゃtzinfo-dataは要らないぽい。Gemfileから削除

あとはRailsのVersionを最新ぽいのに固定してGemfile更新、再度
```sh
$ root@d5c9f216efb4:/moko_test# bundle update
```

### とりあえずRailsインスコ確認
```sh
$ root@d5c9f216efb4:/moko_test# bin/rails c
Running via Spring preloader in process 1438
Loading development environment (Rails 5.1.2)
irb(main):001:0>
```

あー、ええ感じや

### rails s 出来るんかね？
```sh
$ root@d5c9f216efb4:/moko_test# bin/rails s -b 0.0.0.0
=> Booting Puma
=> Rails 5.1.2 application starting in development on http://0.0.0.0:3000
=> Run `rails server -h` for more startup options
Puma starting in single mode...
* Version 3.9.1 (ruby 2.4.1-p111), codename: Private Caller
* Min threads: 5, max threads: 5
* Environment: development
* Listening on tcp://0.0.0.0:3000
Use Ctrl-C to stop
```

あー、ええ感じや [http://localhost:3000](http://localhost:3000)

### Railsのコンテナに新たに接続したい
```sh
$ docker exec -it moko_test bash
root@56ce6da9ab90:/moko_test#
```

きてるきてる

### Railsから接続するmariadbのコンテナを起動してみる

まぁコンテナをビルドする必要もなく、直接runする

```sh
$ docker run -d --name mariadb -e MYSQL_ROOT_PASSWORD=hogehoge mariadb:10.3.0
```

### 確認してみる
```sh
$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
c13912e39783        mariadb:10.3.0      "docker-entrypoint..."   10 seconds ago      Up 9 seconds        3306/tcp                 mariadb
```

あー起動してるっぽい

### Railsのコンテナからリンクするように再起動する

```sh
# コンテナ終了(exit)してから

$ docker run -it --rm --name moko_test -v "$PWD":/moko_test -p 3000:3000 --link mariadb:mariadb moko_test:2.4.1 bash
```

### 確認してみる

```sh
root@0a40e45cac6b:/moko_test# env | grep MARIADB
MARIADB_ENV_MARIADB_VERSION=10.3.0+maria~jessie
MARIADB_PORT=tcp://172.17.0.3:3306
MARIADB_PORT_3306_TCP=tcp://172.17.0.3:3306
MARIADB_PORT_3306_TCP_PORT=3306
MARIADB_ENV_MYSQL_ROOT_PASSWORD=hogehoge
MARIADB_PORT_3306_TCP_PROTO=tcp
MARIADB_ENV_GOSU_VERSION=1.7
MARIADB_ENV_no_proxy=*.local, 169.254/16
MARIADB_NAME=/moko_test/mariadb
MARIADB_ENV_MARIADB_MAJOR=10.3
MARIADB_PORT_3306_TCP_ADDR=172.17.0.3
```

あー、たぶんこれでいいんじゃないかな

### DB接続確認ってどうやる？
とりあえずダミーのmodelとmigrate作ってみるのがいいのか？

```sh
root@0a40e45cac6b:/moko_test# bin/rails g model Temp name:string
Running via Spring preloader in process 46
      invoke  active_record
      create    db/migrate/20170630152109_create_temps.rb
      create    app/models/temp.rb
```

config/database.yml を修正して、接続先を環境変数から取得するようにする

```ruby
default: &default
  adapter: mysql2
  encoding: utf8
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: root
  password: <%= ENV.fetch('MARIADB_ENV_MYSQL_ROOT_PASSWORD') %>
  host: <%= ENV.fetch('MARIADB_PORT_3306_TCP_ADDR') %>
```

migrateする

```sh
root@0a40e45cac6b:/moko_test# bin/rails db:create
Created database 'moko_test_development'
Created database 'moko_test_test'

root@0a40e45cac6b:/moko_test# bin/rails db:migrate
== 20170630152109 CreateTemps: migrating ======================================
-- create_table(:temps)
   -> 0.0843s
== 20170630152109 CreateTemps: migrated (0.0846s) =============================
```

確認してみる

```sh
root@0a40e45cac6b:/moko_test# bin/rails db:create
Created database 'moko_test_development'
Created database 'moko_test_test'

root@0a40e45cac6b:/moko_test# bin/rails db:migrate
== 20170630152109 CreateTemps: migrating ======================================
-- create_table(:temps)
   -> 0.0843s
== 20170630152109 CreateTemps: migrated (0.0846s) =============================

root@0a40e45cac6b:/moko_test# bin/rails c
Running via Spring preloader in process 131
Loading development environment (Rails 5.1.2)

irb(main):001:0> Temp.create(name: 'moko')
   (0.8ms)  SET NAMES utf8,  @@SESSION.sql_mode = CONCAT(CONCAT(@@sql_mode, ',STRICT_ALL_TABLES'), ',NO_AUTO_VALUE_ON_ZERO'),  @@SESSION.sql_auto_is_null = 0, @@SESSION.wait_timeout = 2147483
   (0.5ms)  BEGIN
  SQL (0.8ms)  INSERT INTO `temps` (`name`, `created_at`, `updated_at`) VALUES ('moko', '2017-06-30 15:27:26', '2017-06-30 15:27:26')
   (25.5ms)  COMMIT
=> #<Temp id: 1, name: "moko", created_at: "2017-06-30 15:27:26", updated_at: "2017-06-30 15:27:26">

irb(main):002:0> Temp.first
  Temp Load (0.8ms)  SELECT  `temps`.* FROM `temps` ORDER BY `temps`.`id` ASC LIMIT 1
=> #<Temp id: 1, name: "moko", created_at: "2017-06-30 15:27:26", updated_at: "2017-06-30 15:27:26">
```

あー、これはイケてるっぽい


### 使わないとは思うけど、mariadbのコンテナに新たに接続したい
```sh
$ docker exec -it mariadb bash
root@4054dedf1f17:/#
```

いいぽい

### 確認してみる
```sh
root@4054dedf1f17:/# mysql -uroot -phogehoge
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 12
Server version: 10.3.0-MariaDB-10.3.0+maria~jessie mariadb.org binary distribution

Copyright (c) 2000, 2016, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> use moko_test_development
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [moko_test_development]> select * from temps;
+----+------+---------------------+---------------------+
| id | name | created_at          | updated_at          |
+----+------+---------------------+---------------------+
|  1 | moko | 2017-06-30 17:13:34 | 2017-06-30 17:13:34 |
+----+------+---------------------+---------------------+
1 row in set (0.00 sec)
```

さっき作ったレコードが見えたりする

### 当然ながら、mariadbのコンテナ削除と同時ににmariadbの中身も失われるので永続化する
mariadbを起動する時に/var/lib/mysqlを適当なローカルにマウントしておく

ただし、この例のようにアプリ内のディレクトリを永続化領域として使うのはどうなのか？は後で調べる

```sh
$ docker run -d --name mariadb -v "$PWD"/docker_data/mariadb/persistent_data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=hogehoge mariadb:10.3.0
```

mariadb落として上げて、データが消えてないことを確認してね

### mariadbのログが見たい
どのレベルのログなのか確認が必要ですが、一応こんな方法もあるぽい

```sh
$ docker logs -f mariadb
```

ログは自分で見て確かめる

### mariadbの設定(my.conf等)を指定したい
まぁマウントですよね

```sh
-v ....../mariadb/config:/etc/mysql
```

上記みたいな感じのオプションでイケる　これは開発環境的にまだ不要かなとも思うのでメモ程度で

### redisも起動しとこう
```sh
$ docker run -d --name redis redis:3.2.9 redis-server
```

検証どうしよう

### とりえあずRailsのコンテナからリンクするように再起動する

```sh
# コンテナ終了(exit)してから

$ docker run -it --rm --name moko_test -v "$PWD":/moko_test -p 3000:3000 --link mariadb:mariadb --link redis:redis moko_test:2.4.1 bash

$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
06e21f7898bc        moko_test:2.4.1     "bash"                   35 seconds ago      Up 33 seconds       0.0.0.0:3000->3000/tcp   moko_test
ff0c78c9b095        mariadb:10.3.0      "docker-entrypoint..."   37 seconds ago      Up 36 seconds       3306/tcp                 mariadb
2ffdb195e704        redis:3.2.9         "docker-entrypoint..."   2 minutes ago       Up 2 minutes        6379/tcp                 redis
```

起動はしてるみたい

### railsコンテナからつながることを検証する
```
root@06e21f7898bc:/moko_test# env | grep REDIS
REDIS_ENV_REDIS_DOWNLOAD_URL=http://download.redis.io/releases/redis-3.2.9.tar.gz
REDIS_PORT_6379_TCP_PROTO=tcp
REDIS_NAME=/moko_test/redis
REDIS_PORT_6379_TCP_ADDR=172.17.0.2
REDIS_ENV_REDIS_DOWNLOAD_SHA=6eaacfa983b287e440d0839ead20c2231749d5d6b78bbe0e0ffa3a890c59ff26
REDIS_PORT_6379_TCP_PORT=6379
REDIS_ENV_GOSU_VERSION=1.10
REDIS_PORT_6379_TCP=tcp://172.17.0.2:6379
REDIS_PORT=tcp://172.17.0.2:6379
REDIS_ENV_REDIS_VERSION=3.2.9

そして・・どうやって繋げてあそぼう
```

### redis 永続化
```
$  docker run -d --name -v "$PWD"/docker_data/redis/persistent_data:/data redis redis:3.2.9 redis-server
```

### redis(redis.conf等)を指定したい
まぁマウントですよね

```sh
docker run -d --name redis \
-v "$PWD"/docker_containers_data/redis/persistent_data:/data \
-v "$PWD"/docker_containers_data/redis/config/redis.conf:/usr/local/etc/redis/redis.conf \
redis:3.2.9 redis-server /usr/local/etc/redis/redis.conf
```

上記みたいな感じのオプションでイケる　これは開発環境的にまだ不要かなとも思うのでメモ程度で


### もちろんredisのログも

```sh
$ docker logs -f redis
```

みれたりもする

### メモ
```sh
これまでどこにも書かなかったけど
$ docker kill moko_test
$ docker stop moko_test
$ docker rm moko_test
これで起動中のコンテナは終了、消え去るでしょう
```

### ではdocker-composeでの起動を試しましょう
docker-compose は複数のコンテナを同時に管理する仕組みです
