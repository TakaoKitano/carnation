#
# Dockerfile for carnation app container
#
FROM tkitano/carnation.base
MAINTAINER tkitano <tkitano@gmail.com>

#
# create and setup user
#
RUN useradd -d /home/carnation -m -s /bin/bash carnation
RUN echo carnation:magomago | chpasswd
RUN echo 'carnation ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/carnation
RUN mkdir -m 755 /home/carnation/.ssh
ADD authorized_keys /home/carnation/.ssh/authorized_keys
ADD id_rsa /home/carnation/.ssh/id_rsa
RUN echo "Host github.com\n\tStrictHostKeyChecking no\n" >> /home/carnation/.ssh/config
RUN chown -R carnation:carnation /home/carnation
RUN chmod 700 /home/carnation/.ssh
RUN chmod 600 /home/carnation/.ssh/id_rsa 
RUN chmod 600 /home/carnation/.ssh/authorized_keys

#
# setup application
#

USER carnation
WORKDIR /home/carnation
RUN git clone git@github.com:kajiwara321/magoch_server.git
WORKDIR /home/carnation/magoch_server
RUN bundle install --path vendor/bundle
ENV PATH /usr/local/bin:$PATH

#
# default env : for alpha user testing
#
ENV CARNATION_S3_BUCKET_NAME carnationdata
ENV CARNATION_MYSQL_HOST carnationdbinstance.cyn734ercsgb.ap-northeast-1.rds.amazonaws.com
ENV CARNATION_REDIS_HOST carnationredis.xrr3n6.0001.apne1.cache.amazonaws.com
