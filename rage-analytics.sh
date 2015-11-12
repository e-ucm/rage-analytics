#!/bin/bash
#
# This script automates deployment and management of the 
# RAGE-Analytics system. The latest version is always available at 
# https://github.com/e-ucm/rage-analytics
# 
# Copyright (C) 2015 RAGE Project - All Rights Reserved
# Permission to copy and modify is granted under the Apache License 
#   (http://www.apache.org/licenses/LICENSE-2.0)
# Last revised 2015/10/11


# help contents
function help() {
cat << EOF
  Usage: $0 [OPERATION | --help]
  
  Manage the RAGE-Analytics system. The system consists of several
  linked services, provided by docker containers. See 
  https://github.com/e-ucm/rage-analytics for details.

  OPERATION one of the following:
    
    install:   Install all requirements (docker, docker-compose) 
               and download updated versions of all container images    
    uninstall: Remove all downloaded container images, 
               freeing disk space
    start:     Launch all containers by stages, giving them 
               time to link to each other                
    stop:      Stop and scrub all containers. 
               *Any information stored in these containers will be lost*
    report:    Generate a report.txt file suitable for filing an issue.
               The report will contain all service logs, and essential data
               on your OS, docker and docker-compose versions.
    restart:   Stop (as above) and then start again
    launch:    Install (as above), and then start;
               Useful in shell scripts
    
  --help    display this help and exit
EOF
}

# main entrypoint, called after defining all functions
function main() {

    if [[ $# -eq 0 ]] ; then
        echo "  Usage: $0 [OPERATION | --help]"
        exit 0
    fi
    
    prepare_output    
    case "$1" in
        "install") \
            install ;;
        "uninstall") \
            check_docker_launched && uninstall ; stop_docker_if_launched ;;
        "start") \
            check_docker_launched && start ;;
        "stop") \
            check_docker_launched && stop ; stop_docker_if_launched ;;
        "restart") \
            check_docker_launched && stop ; check_docker_launched && start ;;
        "launch") \
            install && start ;;
        "report") \
            report ;;
        "--help") \
            help ;;
        *) echo \
            "  Usage: $0 [OPERATION | --help]" \
            && echo "   ('$1' is NOT a valid operation)'" ;;        
    esac
}

# only for installs
function require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "need super-user (root) privileges to run this script; exiting" 1>&2
    exit 1
  fi
}

# color setup (for pretty output)
function prepare_output() {
    # modified from http://unix.stackexchange.com/a/10065/69064
    if [ -t 1 ]; then
        ncolors=$(tput colors)
        if test -n "$ncolors" && test $ncolors -ge 8; then
            normal="$(tput sgr0)"
            red="$(tput setaf 1)"
            green="$(tput setaf 2)"
            yellow="$(tput setaf 3)"
            blue="$(tput setaf 4)"
        fi
    fi
}

# pretty output
function recho() {
  echo "${red}R${yellow}A${green}G${blue}E${normal} $@"
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

# builds a report-file, which can be used to help resolve issues
function report() {
  REPORT_FILE="report-$(date -Iminutes | sed -e "s/[:T-]/_/g;s/[+].*//").txt"

  recho "      Generating ${REPORT_FILE}"
  recho "-------------------------------"
  
  recho " ... adding your docker version"
  echo "[Docker version]" > ${REPORT_FILE}
  docker -v >> ${REPORT_FILE}
  
  recho " ... adding your docker-compose version"
  echo "[Docker-compose version]" >> ${REPORT_FILE}
  docker-compose -v >> ${REPORT_FILE}
  
  recho " ... adding kernel version and linux distribution string"
  echo "[Kernel and distro]" >> ${REPORT_FILE}
  uname -a >> ${REPORT_FILE}
  cat /etc/lsb-release >> ${REPORT_FILE}
  
  recho " ... adding your username and group-names"
  echo "[Root or docker-group?]" >> ${REPORT_FILE}
  whoami | grep root >> ${REPORT_FILE}
  groups | grep docker >> ${REPORT_FILE}
  
  recho " ... adding memory, disk space and CPU info"
  echo "[User and groups]" >> ${REPORT_FILE}
  free >> ${REPORT_FILE}
  df -h >> ${REPORT_FILE}
  cat /proc/cpuinfo >> ${REPORT_FILE}
    
  recho " ... adding output of docker-compose ps"
  echo "[Output of docker-compose ps]" >> ${REPORT_FILE}
  docker-compose ps >> ${REPORT_FILE}
  
  recho " ... adding output of docker-compose logs"
  echo "[Output of docker-compose logs]" >> ${REPORT_FILE}
  for SERVICE in $(docker ps -q | xargs) ; do
    recho " ... including $SERVICE "
    echo "[service]--------------------------------------" >> ${REPORT_FILE}
    docker ps | grep $SERVICE >> ${REPORT_FILE}
    echo "[stats]--------------------------------------" >> ${REPORT_FILE}
    docker stats --no-stream=true $SERVICE >> ${REPORT_FILE}
    echo "[logs]--------------------------------------" >> ${REPORT_FILE}
    ( docker logs $SERVICE 2>&1 ) | sed -e 's/\^M/\n/g' \
      | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" >> ${REPORT_FILE} 
  done
  recho " file issues at https://github.com/e-ucm/rage-analytics/issues"
  recho " including ${REPORT_FILE} as an attachment"
}

# installs compose
function update_compose() {
  if ( version_ge 'docker' '1.7' ) ; then
    require_root
    curl -sSL https://get.docker.com/ | sh 
    ( docker daemon & )
    sleep 2s
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

# retrieve space-separated list of images from docker-compose.yml file
function image_list() {
grep "image:" docker-compose.yml \
    | awk '{print $2, " "}' \
    | xargs
}

# retrieve space-separated list of containers from docker-compose.yml file
function service_list() {
grep -E "^[a-z-]+:" docker-compose.yml \
    | sed -e "s/://" | xargs
}

# gets composition file and pulls all images from DockerHub
function get_composition_and_containers() {
  BASE="https://raw.githubusercontent.com/e-ucm/rage-analytics/"
  COMPOSE_YML="${BASE}master/docker-compose.yml"
  wget ${COMPOSE_YML} -O docker-compose.yml  
  recho "      Downloading images"
  recho "-------------------------------"
  for IMAGE in $(image_list) ; do
    docker pull $IMAGE
  done
}

# launches containers and then waits $1 seconds
function launch_and_wait() {
  DELAY=$1
  shift
  SERVICES=$@
  recho
  recho "... launching $SERVICES and waiting $DELAY seconds ..."
  recho
  docker-compose up -d --force-recreate --no-deps $SERVICES &
  sleep "${DELAY}s"
}

# check docker running; start if not
function check_docker_launched() {
  if ( docker info > /dev/null 2>&1 ) ; then
    recho "(docker daemon already running; this is good)"
    DOCKER_WAS_RUNNING=1
  else 
    recho "docker not running; attempting to launch it ..."
    require_root
    ( docker daemon & )
    sleep 2s
  fi
}

# stop docker (for stop, uninstall scripts) if it was not already running
function stop_docker_if_launched() {
  if [ -z "$DOCKER_WAS_RUNNING" ] ; then
    recho "stopping docker daemon as part of cleanup ..."
    require_root
    killall docker
  fi
}

# install dependencies, download images
function install() {
  update_compose
  get_composition_and_containers
}


# uninstall: remove images
function uninstall() {
  stop
  RAGE_IMAGES=$(docker images -q 'eucm/*')
  if [ -z "$RAGE_IMAGES" ] ; then
  recho "no RAGE images to remove."
  else 
    recho "       Removing images"
    recho "-------------------------------"
    docker rmi $RAGE_IMAGES
  fi   
}

# start containers
function start() {
  recho "       Launching images"
  recho "-------------------------------"
  launch_and_wait 60 redis mongo elastic kzk
  launch_and_wait 50 nimbus lrs
  launch_and_wait 5 realtime
  launch_and_wait 30 a2 supervisor ui
  launch_and_wait 10 back front lis
  recho ' * use "docker-compose logs <service> to inspect service logs'
  recho ' * use "docker-compose ps" to see status of all services'
  recho 'output of "docker-compose ps" follows:'
  docker-compose ps
}

# stop & purge containers
function stop() {
  recho "       Stopping containers"
  recho "-------------------------------"
  docker-compose kill
  docker-compose rm -f -v
}

# entrypoint
main $@