# carnation api server

## webtest on dev server (54.178.141.213)

http://dev.mago-ch.com/webtest/index.html kenken/magomago

## server setup

###server env

ubuntu 14.04 LTS server

- adduser carnation
- add magoaws.pem as ~/.ssh/id_rsa

### make sure to take the latest

<pre>
sudo apt-get -y update
</pre>

### basic stuff

<pre>
sudo apt-get -y install wget curl git pkg-config
</pre>

### redis client

<pre>
sudo apt-get -y install redis-tools
</pre>

### for rmagick, avconv

<pre>
sudo apt-get -y install imagemagick libmagickwand-dev libmagic-dev libav-tools libimage-exiftool-perl
</pre>

### mysql client

<pre>
sudo apt-get install -y libmysqlclient-dev mysql-client
</pre>

### git repository

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

### nginx 

<pre>
sudo apt-get install -y nginx
sudo cp conf/nginx.conf /etc/nginx/nginx.conf
edit /etc/nginx/nginx.conf and remove the "daemon off" line (as this is for docker container)
sudo service nginx restart
</pre>

### setup db (needed only if you setup a new database)

<pre>
$ cat db/initialize_database.sql | mysql -u root (or create account on AWS admin console)
$ rake db:migrate
$ rake db:builtin_accounts
$ rake db:testdata
</pre>

### setup 

<pre>
$ cd magoch_server 
$ bundle install --path vendor/bundle
$ cd scripts
$ cp test.env carnation.env (or use production.env)
$ source carnation.env
$ cd ..
$ rake tests
</pre>

### run server

<pre>
$ cd /home/carnation/magoch_server
$ mkdir log
$ source scripts/carnation.env
$ rake resque:stop
$ rake resque:start
$ rake server:stop
$ rake server:start
</pre>

# docker instructions

## build and push image (on a development machine)

### install docker on ubuntu (you don't need this on CoreOS)

<pre>
$ curl -sSL https://get.docker.io/ubuntu/ | sudo sh
</pre>

### prepare and push image

<pre>
rake docker:build
rake docker:push
</pre>

# deploy instructions

## launch ec2 instance

- login to AWS console 
- open https://coreos.com/docs/running-coreos/cloud-providers/ec2/ in a separate browser tab
- click ami-ab9fbeaa (this will be changed) in the ap-northeast-1 HVM section
- you should have opened the AWS EC2 launch wizard page
- select t2.medium type
- check 'Protect against accidental termination'
- storage size is default (8GB)
- config tags appropriately
- select 'default security group' from the existing security group
- select 'magoaws'  key pair
- open AWS EC2 instance tab and wait for it is launched
- note the public ip address of the instance just launched

## copy scripts to a server

<pre>
$ scp -i doc/magoaws.pem scripts/*  core@EC2_PUBLIC_IP_ADDRESS:
$ scp -i doc/magoaws.pem -r conf core@EC2_PUBLIC_IP_ADDRESS:
</pre>

## login to the server

<pre>
$ ssh -i doc/magoaws.pem core@EC2_PUBLIC_IP_ADDRESS
</pre>


## config on the server

<pre>
$ cp production.env carnation.env (or cp test.env carnation.env)
</pre>

## pull docker images (this should take some time)

<pre>
$ docker pull chikaku/carnation
$ docker pull google/cadvisor
</pre>

## config CoreOS to auto start carnation and cadvisor service

<pre>
$ sudo systemctl enable /home/core/carnation.service
$ sudo systemctl enable /home/core/cadvisor.service
</pre>

## run carnation and cadvisor server on the target server

<pre>
$ sudo systemctl start carnation.service
$ sudo systemctl start cadvisor.service
</pre>

## add to the load balancer

- on AWS console EC2 ELB, in the instances tab, add the server to the load balancer
