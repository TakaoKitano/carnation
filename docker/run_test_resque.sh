PWD=`pwd`
mkdir -p var
sudo docker run -d --env-file=test.env -v $PWD/var:/home/carnation/magoch_server/var -t tkitano/carnation.app bundle exec ruby resque/launch_resque_worker.rb
