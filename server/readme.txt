#
# how to install nginx config file and carnation startup scripts
# (you may not need to do this as ec2 instance is created from the image)
#
sudo cp etc/nginx/nginx.conf /etc/nginx

sudo cp etc/init.d/carnation-api-server /etc/initd.d
chmod +x /etc/init.d/carnation-api-server
sudo update-rc.d carnation-api-server defaults

sudo cp etc/init.d/carnation-resque-worker /etc/initd.d
chmod +x /etc/init.d/carnation-resque-worker
sudo update-rc.d carnation-resque-worker defaults
