#!/bin/bash
echo retrieving docker image chikaku/carnation - this may take for a while
docker pull chikaku/carnation >/dev/null
docker images | grep chikaku
echo configure systemd services for carnation
sudo systemctl enable /home/core/carnation.service 
sudo systemctl daemon-reload
sudo systemctl stop carnation.service
sudo systemctl start carnation.service

echo retrieving fluentd image chikaku/fluentd - this may take for a while
docker pull chikaku/fluentd >/dev/null
docker images | grep fluentd
echo configure systemd services for fluentd
sudo systemctl enable /home/core/fluentd.service
sudo systemctl daemon-reload
sudo systemctl stop fluentd.service
sudo systemctl start fluentd.service

sleep 5
docker ps
docker inspect carnation
docker inspect fluentd
