# 1. 素のdocker runで起動する

私はRailsで試行錯誤する為に小さいRailsアプリのDocker開発環境を作りました

まずはDockerfile。変な事をしていないか中を確認する

## buildする

```
docker image build -t docker_rails_test_image -f Dockerfile .
```

## docker-networkを新規作成しないとダメだった

```
docker network ls
docker network create docker-test-network

# 忘れた頃に消す
# docker network rm docker-test-network
```

## MariaDB軽く起動

サクッと起動。永続化とかはここでは考えてない

```
docker run --name docker_mariadb_test \
           --net docker-test-network \
           -e MYSQL_ROOT_PASSWORD=hogehoge \
           -p 3306:3306 \
           -d mariadb:10.4.2
```

確認

```
docker container ls -a
```

## Railsアプリ起動

MACなら 'consistency=cached' 重要だった

```
docker run -it \
           --name docker_rails_test \
           --net docker-test-network \
           --mount type=bind,src=$(pwd),dst=/docker_rails_test,consistency=cached \
           -p 3000:3000 \
           docker_rails_test_app \
           bash
```

プロンプトが変わり、もう中に入ってます

### いつもの

```
bundle check || bundle install
bin/rake db:create db:migrate db:seed
bin/rails s
# bundle exec pumactl start
```

- http://localhost:3000
- http://localhost:3000/rails/info/properties
- http://localhost:3000/rails/info/routes

# 2. docker-composeを使ってみる

次はdocker-compose.yml。変な事をしていないか中を確認する

MariaDBの永続化とか実はやってる

## docker-networkはもう要らない

```
docker network ls
docker network rm docker-test-network
```

## はい起動。同時に管理できる

```
docker-compose up
```

## いつもの

```
bin/bundle check || bin/bundle install
bin/rake db:create db:migrate db:seed
bin/rails s
# bin/bundle exec pumactl start
```

- http://localhost:3000
- http://localhost:3000/rails/info/properties
- http://localhost:3000/rails/info/routes

## 別ターミナルからの接続

```
docker-compose exec app bash
```

# 3. rails newした時のメモ

```
rails new docker_rails_test_app \
  --database=mysql \
  --skip-action-mailer \
  --skip-action-cable \
  --skip-active-storage \
  --skip-yarn \
  --skip-coffee \
  --skip-turbolinks \
  --skip-test \
  --skip-bundle \
  --skip-git

bin/rails generate scaffold User name:string
```

# 4. おまけ

```
# ログ観る
docker-compose logs
docker-compose logs -f

# 全ての停止中のコンテナ、ボリューム、ネットワーク、イメージを一括削除する
docker system prune

# 使われていないimageを一括削除する
docker image prune
docker image ls -a

# 停止しているコンテナをすべて削除
docker container prune
ocker container ls -a

# 使っていないnetworkの一括削除
docker network prune
docker network list

# どのコンテナからも使われていないボリュームの削除
docker volume prune
docker volume ls
```
