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
# ruby
#
RUN mkdir /root/ruby
WORKDIR /root/ruby
RUN wget http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.gz
RUN tar xvzf ruby-2.1.2.tar.gz
WORKDIR /root/ruby/ruby-2.1.2
RUN ./configure --prefix=/usr/local
RUN make && make install
RUN gem install fluentd --no-ri --no-rdoc

#
# setup volume
#
RUN mkdir -p /home/carnation/magoch_server
WORKDIR /home/carnation/magoch_server
VOLUME ["/home/carnation/magoch_server/log"]
VOLUME ["/home/carnation/magoch_server/conf"]

ENV PATH /usr/local/bin:$PATH
CMD ["/usr/local/bin/fluentd", "-c", "conf/fluentd.conf"]

