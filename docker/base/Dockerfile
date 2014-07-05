#
# carnation base Dockerfile
#

FROM dockerfile/ubuntu
MAINTAINER tkitano <tkitano@gmail.com>

#
# install build essentials
#
RUN apt-get -qq update
RUN apt-get -qy install wget curl git pkg-config dialog build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev openssl

#
# ssh server
#
RUN apt-get -qy install openssh-server
VOLUME ["/var/run/sshd"]

#
# redis client
#
RUN apt-get -qy install redis-tools

#
# image magick
#
RUN apt-get -qy install imagemagick libmagickwand-dev libmagic-dev libav-tools libimage-exiftool-perl

#
# mysql client
#
RUN apt-get -qy install libmysqlclient-dev mysql-client

#
#
# ruby
#
RUN mkdir /root/ruby
WORKDIR /root/ruby
RUN wget http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.gz
RUN tar xvzf ruby-2.1.2.tar.gz
WORKDIR /root/ruby/ruby-2.1.2
RUN ./configure --prefix=/usr/local
RUN make && make install
RUN gem install bundler
