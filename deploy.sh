#!/bin/bash

# It defines two commands, prod (p) and dev (d)
#
# -p [prod]: It deploys the production stack
# -d [dev] : It deploys the development stack
#
# It requires the following files:
# - docker-compose.yml: The docker-compose file for the production stack
# - docker-compose.dev.yml: The docker-compose file for the development stack
#
# It requires the following commands:
# - docker
# - docker-compose
#
# It requires the following permissions:
# - The user must be able to run docker commands
# - The user must be able to run docker-compose commands
#
# USAGE:
# ./deploy.sh -p # deploys the production stack
# ./deploy.sh -d # deploys the development stack (adds intermediate nginx proxy)
#

while getopts ":pd" opt; do
  case $opt in
    p)
      prod="prod"
      ;;
    d)
      dev="dev"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

if [ "$prod" = "prod" ]; then
    echo "Deploying production stack"
    docker network create vapor --driver bridge --attachable || echo "Network already exists"
    docker network create vapor_database --driver bridge --attachable || echo "Network already exists"
    docker-compose -f docker-compose.yml down -v || echo "Error stopping vapor stack"
    docker-compose -f docker-compose.yml build --progress=plain || echo "Error building vapor stack"
    docker-compose -f docker-compose.yml up -d --remove-orphans
    docker system prune -a -f
elif [ "$dev" = "dev" ]; then
    echo "Deploying development stack"
else
    echo "Invalid option"
fi