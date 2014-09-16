#!/bin/bash
echo retrieving docker image chikaku/carnation - this may take long time
docker pull chikaku/carnation >/dev/null
docker images | grep chikaku
echo configure systemd services for carnation
sudo systemctl enable /home/core/carnation.service 
sudo systemctl daemon-reload
sudo systemctl start carnation.service
#echo retrieving docker image google/cadvisor for memory trace - this may take long time
#docker pull google/cadvisor >/dev/null
#docker images | grep cadvisor
#sudo systemctl enable /home/core/cadvisor.service
#sudo systemctl stop cadvisor.service
#sudo systemctl start cadvisor.service
sleep 5
docker ps
docker inspect carnation
