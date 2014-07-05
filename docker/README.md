# how to prepare docker images and run application in the container

## prepare base image

This base image contains sshd server, build tools, mysql client, redis client and ruby.
<pre>
cd base
sudo docker build -t tkitano/carnation.base .
</pre>

## prepare app image

This image contains the carnation application. 
Do not push the image to public hub.

<pre>
cd app
sudo docker build --no-cache -t tkitano/carnation.app .
</pre>

## run carnation API server

- create AWS EC2 instance ubuntu 64bit
- adduser carnation
- config /home/carnation/.ssh appropriately
- apt-get update
- apt-get install git
- cd /home/carnation && git clone git@github.com:kajiwara321/magoch_server.git
- install docker  (http://docs.docker.com/installation/ubuntulinux/ the latest version of Docker)
- apt-get install nginx
- modify /etc/nginx/nginx.conf and restart nginx
<pre>
        #
        # carnation server
        #
        upstream carnation_server {
            server localhost:9292 fail_timeout=0;
        }
        server {
          server_name test.mago-ch.com;
          root /home/carnation/magoch_server/public;
          location /token {
            proxy_pass http://carnation_server;
          }
          location /api/v1 {
            proxy_pass http://carnation_server;
          }
          location /webtest {
            auth_basic  "webtest access restricted";
            auth_basic_user_file "/home/carnation/magoch_server/server/htpasswd.webtest";
            try_files $uri $uri/ /index.html;
          }
        }
</pre>

### deploy carnation server on an AWS EC2 instance

<pre>
cd /home/carnation/magoch_server/docker
sudo docker run -d -p 9292:9292 -t tkitano/carnation.app rake server:start
sudo docker run -d -t tkitano/carnation.app rake resque:start
</pre>

### test carnation server on a local machine

<pre>
cd /home/carnation/magoch_server/docker
sudo docker run --env-file=local.env -p 9292:9292 --net=host -v /var/run/mysqld:/var/run/mysqld -t tkitano/carnation.app rake server:start
sudo docker run --env-file=local.env --net=host -v /var/run/mysqld:/var/run/mysqld -t tkitano/carnation.app rake resque:start
</pre>
