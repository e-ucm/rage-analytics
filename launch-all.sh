#!/bin/bash

IMAGES=$(grep "image:" docker-compose.yml \
  | awk '{print $2, " "}' \
  | xargs)

function launch() {
  DELAY=$1
  shift
  SERVICES=$@
  echo
  echo "... launching $SERVICES and waiting $DELAY seconds ..."
  echo
  docker-compose up $SERVICES &
  sleep "${DELAY}s"
}

echo "      Downloading images"
echo "-------------------------------"
for IMAGE in $IMAGES ; do
  docker pull $IMAGE
done

echo "       Launching images"
echo "-------------------------------"
launch 60 redis mongo elastic kzk
launch 50 nimbus lrs
launch 30 a2 supervisor ui realtime
launch 10 back front lis

echo "     All images launched"
echo "-------------------------------"
docker-compose ps