sudo docker login 
sudo docker pull tkitano/carnation.app
sudo docker kill $(docker ps -q)
sudo docker rm $(docker ps -aq)
sudo docker run -d -p 9292:9292 -t tkitano/carnation.app rake server:start
sudo docker run -d -t tkitano/carnation.app rake resque:start

