# carnation api server

## webtest

- beta production server http://beta.mago-ch.com/webtest/index.html 
- test staging server http://test.mago-ch.com/webtest/index.html 

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

### carnation env and certificates (you need to get those files from chikaku)

- install envfile/test.env
- install envfile/production.env
- install conf/mago-ch.com.crt
- install conf/mago-ch.key
- install conf/htpasswd.webtest

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

### Packer 

- download appropriate binary package from https://www.packer.io/downloads.html
- extract the package
- set PATH to the extracted packer binaries

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
- set storage size to 24GB
- config tags appropriately (please add tags - creator:yourname, purpose:test or beta)
- select 'default security group' from the existing security group
- select 'magoaws'  key pair
- open AWS EC2 instance tab and wait for it is launched
- note the public ip address of the instance just launched
- run carnation_deploy.sh {test|production} server_address

or

- rake packer:production_image
- rake packer:test_iamge
- launch the EC2 instance using the AMI image built by packer (you still need to specify the correct security group and ssh key pair)


## add to the load balancer

- on AWS console EC2 ELB, in the instances tab, add the server to the load balancer
- wait a few minutes to the load balancer status is changed to 'InService' (this may take time)
