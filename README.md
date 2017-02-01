# dockerでRailsの開発環境テスト

- まずは各コンテナのテストを行い、後で 連携させながら Docker-Compose に移行する
- 各コンテナのversion指定はしといた方が良いかなと

## mariadb

こんな感じか？

```sh
docker run -d --name my_mariadb -e MYSQL_ROOT_PASSWORD=hogehoge mariadb:10.1.21
```

確認

```sh
# 接続
docker exec -it my_mariadb bash

mysql -uroot -phogehoge
show databases;

exit
```

## redis

- データの永続化は RDB, docker_containers_data/redis/ にとりあえず
  - 後でデータボリュームコンテナ化とやら？

こんな感じか？

```sh
export ROOT_REPO=/path/to/docker_rails_test

docker run -d --name my_redis \
-v $ROOT_REPO/docker_containers_data/redis/persistent_data:/data \
-v $ROOT_REPO/docker_containers_data/redis/log:/var/log \
-v $ROOT_REPO/docker_containers_data/redis/redis.conf:/usr/local/etc/redis/redis.conf \
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
