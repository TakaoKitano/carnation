
sudo apt-get update

#
# if you use lxc, install now 
#
sudo apt-get install debootstrap 
sudo apt-get install lxc 
sudo apt-get install lxctl
sudo lxc-create -t ubuntu -n carnation
sudo lxc-start -n carnation -d -c /var/lxc-console.log
sudo lxc-console -n carnation

# login to the lxc-console ubuntu/ubuntu

sudo apt-get -y update
sudo apt-get -y install wget curl git

#
# adduser kita
# add kita to sudo group (/etc/group)
# ifconfig to get the IP address (might be 10.0.3.*)
# scp -r .ssh kita@10.0.3.59:.ssh
# git config --global user.email "tkitano@gmail.com"
# git config --global user.name "Takao Kitano"
#

#
# install ruby2.1
#
sudo apt-get -y install build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev
mkdir ~/ruby
cd  ~/ruby
wget http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.1.tar.gz
tar -xvzf ruby-2.1.1.tar.gz
cd ruby-2.1.1
./configure --prefix=/usr/local
make && make check
sudo make install

#
# install mysql
#
sudo apt-get install -y libmysqlclient-dev mysql-client-5.5
sudo apt-get install -y mysql-server-5.5

#
# git clone
#
git clone ssh://git@183.181.164.122:3843/home/git/carnation

#
# setup bundler
#
sudo gem install bundler

#
# install gems
#
cd carnation
bundle install --path vendor/bundle

#
# create database, setup account (you only need to do this once) 
#
mysql -u root <migrate/setupdb.sql

#
# create tables, populate first test data (you need to do every time you modify schema)
#
bundle exec ruby migrate/db_init.rb

#
# have fun
#
bundle exec irb 
require './models'

or
 
bundle exec rackup
test/get_apptoken.sh
test/get_stbtoken.sh
export TOKEN=xxx
test/apicall.sh
