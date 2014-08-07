# carnation api server

## webtest on dev server (54.178.141.213)

http://dev.mago-ch.com/webtest/index.html kenken/magomago

## server setup

###server env

ubuntu 14.04 LTS server

### make sure to take the latest

<pre>
sudo apt-get -y update
</pre>

### basic stuff

<pre>
sudo apt-get -y install wget curl git pkg-config
</pre>

### nginx

<pre>
sudo apt-get -y install nginx
</pre>

modify /etc/nginx/nginx.conf

<pre>
        #
        # carnation server
        #
        upstream carnation_server {
            server localhost:9292 fail_timeout=0;
        }
        server {
          server_name test.mago-ch.com;
          root /home/carnation/magoch_server/public;
          location /token {
            proxy_pass http://carnation_server;
          }
          location /api/v1 {
            proxy_pass http://carnation_server;
          }
          location /webtest {
            auth_basic  "webtest access restricted";
            auth_basic_user_file "/home/carnation/magoch_server/server/htpasswd.webtest";
            try_files $uri $uri/ /index.html;
          }
        }
</pre>

### redis for resque worker

<pre>
sudo apt-get -y install redis-server
</pre>

### for rmagick, avconv

<pre>
sudo apt-get -y install imagemagick libmagickwand-dev libmagic-dev libav-tools libimage-exiftool-perl
</pre>

### mysql (server will not be used, but for now it's needed)

<pre>
sudo apt-get install -y libmysqlclient-dev mysql-client
sudo apt-get install -y mysql-server
</pre>

### setup 

<pre>
$ git clone git@github.com:kajiwara321/magoch_server.git
</pre>

### ruby2.1

<pre>
sudo apt-get -y install build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev
mkdir ~/ruby
cd  ~/ruby
wget http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.gz
tar -xvzf ruby-2.1.2.tar.gz
cd ruby-2.1.2
./configure --prefix=/usr/local
make && make check
sudo make install
sudo gem install bundler
</pre>


### setup 

<pre>
$ cd magoch_server 
$ bundle install --path vendor/bundle
$ mysql -u root <db/initialize_database.sql (or create db in AWS admin console RDS)
</pre>

select one of environment:

-production.env
-test.env
-local.env

<pre>
$ rake db:migrate
$ rake db:builtin_accounts
$ rake db:testdata
$ rake spec
</pre>

if it's first time you perform migration, you need to drop tables in order to migrates
you must backup data before that

<pre>
$ rake db:backup
$ rake db:drop
$ rake db:migrate
$ rake db:restore
$ rake spec
</pre>

or if you are sure migration doesn't destroy existing data

<pre>
$ rake db:migrate
$ rake spec
</pre>

### run server

<pre>
$ cd /home/carnation/magoch_server
$ git pull origin master
$ bundle install --path vendor/bundle
$ rake resque:stop
$ rake resque:start
$ rake server:stop
$ rake server:start
</pre>

# docker instructions

### prepare and push image

<pre>
rake docker:build
rake docker:push
</pre>

### copy scripts to a server (AWS EC2 CoreOS instance will be used)

<pre>
scp -i doc/magoaws.pem run_docker.sh  core@ec2_instance_address:
scp -i doc/magoaws.pem production.env core@ec2_instance_address:
scp -i doc/magoaws.pem test.env core@ec2_instance_address:
</pre>

### run programs on the target server

<pre>
sudo docker login 
sudo docker pull chikaku/carnation
sudo docker kill $(sudo docker ps -q)
source ./production.env (or test.env)
./run_docker.sh
</pre>
