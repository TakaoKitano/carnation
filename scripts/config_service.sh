#!/bin/bash
echo retrieving docker image chikaku/carnation - this may take long time
docker pull chikaku/carnation >/dev/null
#echo retrieving docker image google/cadvisor for memory trace - this may take long time
#docker pull google/cadvisor >/dev/null
docker images | grep chikaku
#docker images | grep cadvisor
echo configure systemd services
sudo systemctl enable /home/core/carnation.service 
#sudo systemctl enable /home/core/cadvisor.service
sudo systemctl daemon-reload
sudo systemctl stop carnation.service
#sudo systemctl stop cadvisor.service
sudo systemctl start carnation.service
#sudo systemctl start cadvisor.service
sleep 5
docker ps
docker inspect carnation
