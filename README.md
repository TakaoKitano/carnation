# carnation api server

# open http://54.238.176.142:9292/webtest/index.html kenken/magomago

## server setup

###server env

ubuntu 12.04 LTS server

### make sure to take the latest

sudo apt-get -y update

### basic stuff
sudo apt-get -y install wget curl git pkg-config

### redis for resque worker

sudo apt-get -y install redis-server

### for rmagick

sudo apt-get -y install imagemagick
sudo apt-get -y install libmagickwand-dev

### ruby2.1

<pre>
sudo apt-get -y install build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev
mkdir ~/ruby
cd  ~/ruby
wget http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.1.tar.gz
tar -xvzf ruby-2.1.1.tar.gz
cd ruby-2.1.1
./configure --prefix=/usr/local
make && make check
sudo make install
</pre>

### mysql (server will not be used, but for now it's needed)

sudo apt-get install -y libmysqlclient-dev mysql-client-5.5
sudo apt-get install -y mysql-server-5.5

### have fun!

- git clone git@github.com:kajiwara321/magoch_server.git
- sudo gem install bundler
- cd magoch_server && bundle install --path vendor/bundle
- mysql -u root <initialize_database.sql
- bundle exec ruby dbinit.rb
- bundle exec resque work -c resque/resque.rc &
- bundle exec rackup




