
sudo apt-get update

sudo apt-get install debootstrap 
sudo apt-get install lxc 
sudo apt-get install lxctl

sudo lxc-create -t ubuntu -n carnation

sudo lxc-start -n carnation -d -c /var/lxc-console.log
sudo lxc-console -n carnation

# login to the lxc-console ubuntu/ubuntu

sudo apt-get -y update
sudo apt-get -y install wget
sudo apt-get -y install curl
sudo apt-get install git

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
cd /usr/local/src
wget http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.1.tar.gz
tar -xvzf ruby-2.1.1.tar.gz
cd ruby-2.1.1/
./configure --prefix=/usr/local
make && make check
sudo make install
#
# setup bundler
#
sudo gem install bundler

#
# install mysql
#
sudo apt-get install -y libmysqlclient-dev
sudo apt-get install -y mysql-client-5.5
sudo apt-get install -y mysql-server-5.5

#
# back up the current system
#
lxc-clone -o carnation -n carnation_2014_04_04

#
# git clone
#
git clone ssh://git@183.181.164.122:3843/home/git/carnation

#
# install gems
#
cd carnation
bundle install --path vendor/bundle

mysql -u root <migrate/setupdb.sql
bundle exec ruby migrate/db_init.rb

bundle exec irb 
require './models'

or
 
bundle exec rackup
test/get_apptoken.sh
test/get_stbtoken.sh
export TOKEN=xxx
test/apicall.sh
