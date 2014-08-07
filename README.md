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
sudo cp conf/nginx.conf /etc/nginx
</pre>

### redis for resque worker

<pre>
sudo apt-get -y install redis-server
</pre>

### for rmagick, avconv

<pre>
sudo apt-get -y install imagemagick libmagickwand-dev libmagic-dev libav-tools libimage-exiftool-perl
</pre>

### mysql (server will not be used, but for now it's needed for testing)

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
$ cat db/initialize_database.sql | mysql -u root (or create account on AWS admin console)
$ source production.env (or test.env)
$ rake db:migrate
$ rake db:builtin_accounts
$ rake db:testdata
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
