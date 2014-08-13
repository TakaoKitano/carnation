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
# redis client, image magick, mysql client, nginx, supervisord
#
RUN apt-get -qy install redis-tools
RUN apt-get -qy install imagemagick libmagickwand-dev libmagic-dev libav-tools libimage-exiftool-perl
RUN apt-get -qy install libmysqlclient-dev mysql-client
RUN apt-get -qy install nginx
RUN apt-get -qy install supervisor

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

#
# setup application
#
RUN mkdir -p /home/carnation/magoch_server
ADD build/magoch_server/Gemfile      /home/carnation/magoch_server/Gemfile
ADD build/magoch_server/Gemfile.lock /home/carnation/magoch_server/Gemfile.lock
WORKDIR /home/carnation/magoch_server
RUN bundle install --path vendor/bundle

#
# launch programs via supervisord
#
ENV PATH /usr/local/bin:$PATH
VOLUME ["/var/run"]
VOLUME ["/home/carnation/magoch_server/log"]
VOLUME ["/home/carnation/magoch_server/conf"]
CMD ["/usr/bin/supervisord","-c", "/home/carnation/magoch_server/conf/supervisord.conf"]

#
# add carnation
#
WORKDIR /home/carnation
ADD build/magoch_server.tgz /home/carnation
WORKDIR /home/carnation/magoch_server
