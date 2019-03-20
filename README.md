# 小さいrailsアプリのDocker開発環境を作る

gemはvendor/bundleにインスコしたかったのでアレコレしてみたが  
**$BUNDLE_APP_CONFIG**周りの問題に太刀打ちできなかったので諦めました  
image内部にインスコします。そのかわり爆速化しました。最初からこうするべきだったんじゃ・・

# 1. 素のdocker runで起動してみる

まずはDockerfile。変な事をしていないか中を確認する

## buildしてみる

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
docker run \
  --name docker_mariadb_test \
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
docker run \
  -it \
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
gem update bundler | bin/bundle update
bin/rails db:create db:migrate db:seed
bundle exec pumactl start
# bundle exec pumactl stop
```

- http://localhost:3000
- http://localhost:3000/users
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
gem update bundler | bin/bundle update
bin/rails db:create db:migrate db:seed
bundle exec pumactl start
# bundle exec pumactl stop
```

- http://localhost:3000
- http://localhost:3000/users
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

```
docker-compose build --no-cache
docker-compose up -d
docker-compose exec app bash
docker-compose logs
docker-compose logs -f
docker-compose logs -f app
docker-compose down
```

ビルド中に落ちても泣かない

```
# 死ぬ直前あたりの状態でコンテナが死んでいるのが見えると思う
docker container ls -a

# イメージとしてコミットする
docker commit 5d0072ce27fc preserve_corpses_image

# その状態でrun
docker run --rm -it preserve_corpses_image bash
 ```
