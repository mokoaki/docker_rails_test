## 素の[docker run]で起動する

### build

```
docker image build -t docker_rails_test_image -f Dockerfile .
```

### docker-networkを新規作成しないとダメだった

```
docker network ls
docker network create hogehoge-network
```

### MariaDB軽く起動

サクッと起動。永続化とか考えてない

```
docker run --name docker_mariadb_test \
           --net hogehoge-network \
           -e MYSQL_ROOT_PASSWORD=hogehoge \
           -p 3306:3306 \
           -d mariadb:10.4.2
```

### 起動、接続

MACなら `consistency=cached` 重要だった

```
docker run --rm -it \
           --name docker_rails_test \
           --net hogehoge-network \
           --mount type=bind,src=$(pwd),dst=/docker_rails_test,consistency=cached \
           -p 3000:3000 \
           docker_rails_test_image bash
```

### 例の

```
bundle check || bundle install
bin/rake db:create db:migrate db:seed
bin/rails s
# bundle exec pumactl start
```

- http://localhost:3000
- http://localhost:3000/rails/info/properties
- http://localhost:3000/rails/info/routes

## docker-compoerを使ってみる

./docker-compose.ymlを配置しました

### docker-networkはもう要らない

```
docker network ls
docker network rm hogehoge-network
```

起動する。一緒に管理できる

```
docker-compose up
```

別ターミナルで
```
docker exec -it docker_rails_test bash

bundle check || bundle install
bin/rake db:create db:migrate db:seed
bin/rails s
```

したり、


```
docker-compose up -d
docker-compose exec app bash

bundle check || bundle install
bin/rake db:create db:migrate db:seed
bin/rails s
```

したりする

他にも

```
docker-compose down
docker-compose logs -f mariadb
```

とかできる便利

## メモ

### 以前は [docker ps] だった

```
docker container ls -a
```

### 以前は [docker images] だった

```
docker image ls
```

### 最初に行った事メモ

```
bundle exec rails new docker_rails_test_app \
  --database=mysql \
  --skip-action-mailer \
  --skip-action-cable \
  --skip-yarn \
  --skip-coffee \
  --skip-turbolinks \
  --skip-test \
  --skip-bundle \
  --skip-git

bin/rails generate scaffold User name:string
```
