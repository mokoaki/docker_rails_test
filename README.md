# dockerでRailsの開発環境テスト

## さっさとやることだけをメモ

```sh
docker-compose up -d
docker exec -it rails bash

bundle install
bin/rake db:create db:migrate
bin/rails s -b 0.0.0.0
```

[http://localhosat:3000](http://localhosat:3000) にアクセス

## まずは各コンテナのテストを行い、後で連携させながら Docker-Compose に移行する

## 何をする
- images
  - ruby
    - rails
  - mariadb
    - root:hogehoge
  - redis
- redis, dbへの接続はunix socketを使う（予定）

## rails

- ruby のイメージを使用する

こんな感じか？

```sh
export ROOT_REPO=/path/to/docker_rails_test

docker run -d -it --name my_rails -w /application -v $ROOT_REPO/application:/application -p 3000:3000 --link my_mariadb:mariadb ruby:2.4.0 bash

# docker rm -f my_rails
```

確認

```sh
# 接続
docker exec -it my_rails bash

bundle install

rails -v

exit
```

## mariadb

- データの永続化は RDB, docker_containers_data/redis/ にとりあえず
  - 後でデータボリュームコンテナ化とやら？

こんな感じか？

```sh
export ROOT_REPO=/path/to/docker_rails_test

docker run -d --name my_mariadb \
-v $ROOT_REPO/docker_containers_data/mariadb/persistent_data:/var/lib/mysql \
-v $ROOT_REPO/docker_containers_data/mariadb/config:/etc/mysql \
-e MYSQL_ROOT_PASSWORD=hogehoge mariadb:10.1.21
```

確認

```sh
# 接続
docker exec -it my_mariadb bash

mysql -uroot -phogehoge
show databases;

exit
```

とりあえずログが見たい
```
docker logs -f my_mariadb
```

## redis

- データの永続化は RDB, docker_containers_data/redis/ にとりあえず
  - 後でデータボリュームコンテナ化とやら？

こんな感じか？

```sh
export ROOT_REPO=/path/to/docker_rails_test

docker run -d --name my_redis \
-v $ROOT_REPO/docker_containers_data/redis/persistent_data:/data \
-v $ROOT_REPO/docker_containers_data/redis/config/redis.conf:/usr/local/etc/redis/redis.conf \
redis:3.2.7 redis-server /usr/local/etc/redis/redis.conf

# docker rm -f my_redis
```

確認

```sh
# 接続
docker exec -it my_redis bash

redis-cli set "a" 12345
redis-cli get "a"

exit

docker stop my_redis
docker rm my_redis
```

とりあえずログが見たい
```
docker logs -f my_redis
```
