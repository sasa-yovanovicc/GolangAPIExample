#!/bin/bash
if [[ `sudo service mysql status | grep "running"` -ne 0 ]]
then
  sudo service mysql stop
fi

./scripts/build_tools_install.sh
./scripts/swagger_code_gen.sh
./scripts/copy_post_code_gen_docker.sh
./scripts/build_vendor.sh
sudo docker-compose up --build