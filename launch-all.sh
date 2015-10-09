#!/bin/bash

# only for installs
function require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
  fi
}

# compares two versions; sort -V is "version sort"
# returns 1 if true
function verlt() {
    [ "$1" = "$2" ] && return 1 \
      || [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

# returns non-empty if version for $1 is >= $2
function version_ge() {
  V="$($1 -v)"
  if ! [ -z "$V" ] ; then 
  echo "$1 found...";
    V=$(echo $V | sed -e "s/[^0-9]*\([0-9.]*\).*/\1/")
    echo "   ... important part of version: $V; required $2"
    if ! ( verlt $V $2 ) ; then
      echo "   ... $1 version considered fine"
      return 1
    fi
  fi
  echo "   ... downloading and installing $1 (root required)"
  return 0
}

# installs compose
function update_compose() {
  if ( version_ge 'docker' '1.7' ) ; then
    require_root
    curl -sSL https://get.docker.com/ | sh 
    ( docker -d & )
  fi
  if ( version_ge 'docker-compose' '1.4.2' ) ; then
    require_root
    COMPOSE_URL="https://github.com/docker/compose/releases/download/"
    SUFFIX="$(uname -s)-$(uname -m)"
    TARGET="/usr/local/bin/docker-compose"
    curl -L "${COMPOSE_URL}1.4.2/docker-compose-${SUFFIX}" > ${TARGET} \
        && chmod +x /usr/local/bin/docker-compose
  fi
}

# gets composition file and pulls all images from DockerHub
function get_composition_and_containers() {
  BASE="https://raw.githubusercontent.com/e-ucm/rage-analytics/"
  COMPOSE_YML="${BASE}master/docker-compose.yml"
  wget ${COMPOSE_YML}
  IMAGES=$(grep "image:" docker-compose.yml \
    | awk '{print $2, " "}' \
    | xargs)
  echo "      Downloading images"
  echo "-------------------------------"
  for IMAGE in $IMAGES ; do
    docker pull $IMAGE
  done
}

# launches containers and then waits $1 seconds
function launch_and_wait() {
  DELAY=$1
  shift
  SERVICES=$@
  echo
  echo "... launching $SERVICES and waiting $DELAY seconds ..."
  echo
  docker-compose up $SERVICES &
  sleep "${DELAY}s"
}

function main() {
  update_compose
  get_composition_and_containers
  echo "       Launching images"
  echo "-------------------------------"
  launch_and_wait 60 redis mongo elastic kzk
  launch_and_wait 50 nimbus lrs
  launch_and_wait 30 a2 supervisor ui realtime
  launch_and_wait 10 back front lis
  echo "     All images launched"
  echo "-------------------------------"
  docker-compose ps
}

main

