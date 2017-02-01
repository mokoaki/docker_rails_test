# dockerでRailsの開発環境テスト

- まずは各コンテナのテストを行い、後で Docker-Compose に移行する

## redis

- version指定はしといた方が良い？
- データの永続化は開発環境なんで特に気にしない
  - 後でデータボリュームコンテナ化
    - 本当はやりたかったけど古いdockerでうまくいけなかった

こんな感じか？

```sh
export ROOT_REPO=/path/to/docker_rails_test

docker run -d --name myredis -v $ROOT_REPO/docker_containers_data/redis.conf:/usr/local/etc/redis/redis.conf redis:3.2.7 redis-server /usr/local/etc/redis/redis.conf
```

### 確認

```sh
# 接続
docker exec -it myredis bash

redis-cli set "a" 12345
redis-cli get "a"

exit
```
