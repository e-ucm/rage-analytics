#!/bin/bash
#
# This script automates deployment and management of the 
# RAGE-Analytics system.
# The latest version is always available at 
# https://github.com/e-ucm/rage-analytics
# 
# Copyright (C) 2015 RAGE Project - All Rights Reserved
# Permission to copy and modify is granted under the Apache License 
#   (http://www.apache.org/licenses/LICENSE-2.0)
# Last revised 2015/26/11

# project-related constants
PROJECT_NAME='rage-analytics'
PROJECT_URL="https://github.com/e-ucm/${PROJECT_NAME}"
PROJECT_RAW_URL="https://raw.githubusercontent.com/e-ucm/${PROJECT_NAME}/"
PROJECT_ISSUE_URL="https://github.com/e-ucm/${PROJECT_NAME}/issues/"
COMPOSE_NET_NAME='rage'
# external constants
MIN_DOCKER_VERSION='1.9'
MIN_COMPOSE_VERSION='1.5'
INSTALL_COMPOSE_VERSION='1.5.0'
DOCKER_SH_URL='https://get.docker.com/'
COMPOSE_BASE_URL='https://github.com/docker/compose/releases/download/'
COMPOSE_INSTALL_TARGET='/usr/local/bin/docker-compose'
# compose settings
COMPOSE_COMMAND="docker-compose --x-networking -p ${COMPOSE_NET_NAME}"
COMPOSE_UP_FLAGS="-d --force-recreate --no-deps"

# help contents
function help() {
cat << EOF
  Usage: $0 [OPERATION | --help]

  Manage the ${PROJECT_NAME} service.
  The system consists of several linked services, provided by docker containers. 
  See ${PROJECT_URL} for details.

  OPERATION one of the following:

    install:     Install all requirements (docker, docker-compose) 
                 and download updated versions of all container images    
    start:       Launch all containers by stages, waiting for dependencies
                 to become available.
    launch:      Install (as above), and then start (as above).
    stop:        Gracefully stop all containers, so that no data is lost;
                 you can then inspect their data in ./data, or restart them.
    purge:       Kill and remove all data in all containers
                 *Any information stored in these containers will be lost*
    restart:     Stop (as above) and then start (as above).
    uninstall:   Purge (as above) and remove all container images, 
                 freeing disk space.
    status:      Display status of all containers.
                 all should be either up or display 'Exit 0' (=normal exit)
    logs <id>:   Display logs of the container with name <id>; 
                 (eg.: 'a2' or 'redis'); use Ctrl+C to exit logs. 
    shell <id>:  Opens a bash shell into the container with name <id>.
                 (eg.: 'a2' or 'redis'); type 'exit' to exit the shell.
    start <ids>: Launch the containers with names in (space-separated) <ids>;
                 dependencies, if any, will not be waited for.
    stop <ids>:  Stop only the container with names in (space-separated) <ids>, 
                 without losing data.
    network:     Display current docker-network names and (internal) IPs;
                 good for general diagnostics.
    report:      Generate a report.txt file suitable for filing an issue;
                 the report will contain logs and information on your machine.

  --help    display this help and exit
EOF
}

# main entrypoint, called after defining all functions (see last line)
function main() {

    if [[ $# -eq 0 ]] ; then
        echo "  Usage: $0 [OPERATION | --help]"
        exit 0
    fi

    prepare_output    
    case "$1" in
        "install")
            install ;;
        "uninstall")
            check_docker_launched && purge && uninstall ; stop_docker_if_launched ;;
        "start")
            if [ -z $2 ] ; then
              check_docker_launched && start 
            else
              shift && check_docker_launched && start_ids $@
            fi ;;
        "stop")
            if [ -z $2 ] ; then
              check_docker_launched && stop && stop_docker_if_launched 
            else
              shift && check_docker_launched && stop_ids $@
            fi ;;
        "purge")
            check_docker_launched && purge ; stop_docker_if_launched ;;
        "restart")
            check_docker_launched && stop ; check_docker_launched && start ;;
        "launch")
            install && start ;;
        "status")
            check_docker_launched && display_status ;;
        "logs")
            if [ -z $2 ] ; then echo "  Missing parameter <id>" ; exit ; fi ;
            check_docker_launched && display_logs $2 ;;
        "shell")
            if [ -z $2 ] ; then echo "  Missing parameter <id>" ; exit ; fi ;
            check_docker_launched && shell_into $2 ;;
        "network")
            check_docker_launched && network ;;
        "report")
            check_docker_launched && report && stop_docker_if_launched ;;
        "--help")
            help ;;
        *) echo \
            "  Usage: $0 [OPERATION | --help]" \
            && echo "   ('$1' is NOT a valid operation)'" ;;        
    esac
}

# ---- 
# ---- Non-command, auxiliary functions start here
# ---- 

# only for installs & uninstalls
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

# installs compose
function update_compose() {
  if ( version_ge 'docker' ${MIN_DOCKER_VERSION} ) ; then
    require_root
    curl -sSL ${DOCKER_SH_URL} | sh 
    docker daemon >docker-log.txt 2>&1 &
    sleep 2s
  fi
  if ( version_ge 'docker-compose' ${MIN_COMPOSE_VERSION} ) ; then
    require_root
    SUFFIX="$(uname -s)-$(uname -m)"
    curl -L "${COMPOSE_BASE_URL}${INSTALL_COMPOSE_VERSION}/docker-compose-${SUFFIX}" \
        > ${COMPOSE_INSTALL_TARGET} \
        && chmod +x ${COMPOSE_INSTALL_TARGET}
  fi
}

# gets composition file and pulls all images from DockerHub
function get_composition_and_containers() {
  BASE="https://raw.githubusercontent.com/e-ucm/rage-analytics/"
  COMPOSE_YML="${BASE}master/docker-compose.yml"
  EXTENSION_YML="${BASE}master/${COMPOSE_FILE}"
  wget ${COMPOSE_YML} -O docker-compose.yml  
  recho "      Downloading images"
  recho "-------------------------------"
  show_and_do ${COMPOSE_COMMAND} pull
}

# displays a command that is going to be run before running it
function show_and_do() {
  echo "running: ${green}$@${green}${normal}"
  $@
}

# launches containers and then waits $1 seconds
function launch_and_wait() {
  DELAY=$1
  shift
  SERVICES=$@
  recho
  recho "... launching ${SERVICES} and waiting ${DELAY} seconds ..."
  recho
  show_and_do ${COMPOSE_COMMAND} up ${COMPOSE_UP_FLAGS} ${SERVICES}
  sleep "${DELAY}s"
}

# poll service until connection succeeds
function wait_for_service() {
  docker_map
  if [ -z ${CONTAINERS[$1]} ] ; then
    echo "Container $1 failed to launch."
    echo "Please run '$0 report' to file a new issue to help us help you."
    exit -1
  fi
  SERVICE_IP=$( docker inspect ${CONTAINERS[$1]} \
    | grep IPAddress | grep -oE '([0-9]{1,3}[.]*){4}' )
  echo -n "Waiting for $1 to be up at ${SERVICE_IP}:$2 ... "
  T=0  
  until netcat -z ${SERVICE_IP} $2 ; do
      sleep 1s
      echo -n "."
      ((T++))
  done
  echo -e "\n OK - $1:$2 ($3) reachable after ${T}s"
}

# check docker running; start if not
function check_docker_launched() {
  if ( docker info > /dev/null 2>&1 ) ; then
    recho "(docker daemon already running; this is good)"
    DOCKER_WAS_RUNNING=1
  else 
    recho "docker not running; attempting to launch it ..."
    require_root    
    docker daemon >docker-log.txt 2>&1 &
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

# map internal docker hashes to container-names and vice-versa
function docker_map() {
  declare -g -A CONTAINERS
  while read -r LINE ; do
    NAME=${LINE##* }
    HASH=${LINE%% *}
    XHASH="x${HASH}"
    CONTAINERS[$XHASH]=$NAME
    CONTAINERS[$NAME]=$HASH
  done < <( docker ps | tail -n +2 | sed -e 's:   .*   : :g' )
}

# ---- 
# ---- Commands start here, in their order according to the help screen
# ---- 

# install dependencies, download images
function install() {
  update_compose
  get_composition_and_containers
}

# start containers
function start() {
 
  composeVersion=$(docker-compose -v)
  IFS=', ' read -r -a array <<< "$composeVersion"

  if [[ "${array[2]}" != "$INSTALL_COMPOSE_VERSION" ]] ; then
      echo "  docker-compose version $INSTALL_COMPOSE_VERSION required, available ${array[2]}"
      exit 0
  fi

  recho "       Launching images"
  recho "-------------------------------"
  
  # ensure data-dirs exist; 'purge' may have removed them
  mkdir -p data/{elastic,kafka,mongo,redis,zookeeper} >/dev/null 2>&1
  
  launch_and_wait 5 mongo redis elastic kzk realtime
  wait_for_service redis 6379 'Redis'
  wait_for_service elastic 9300 'ElasticSearch'
  wait_for_service kzk 9092 'Apache Kafka'
  wait_for_service kzk 2181 'Apache ZooKeeper'
  wait_for_service mongo 27017 'MongoDB'
  
  launch_and_wait 5 nimbus lrs
  wait_for_service nimbus 6627 'Apache Storm - Nimbus'
  wait_for_service lrs 8080 'Apereo OpenLRS'
  
  launch_and_wait 5 a2 supervisor ui
  wait_for_service a2 3000 'RAGE Authentication & Authorization'
  # no problem if Storm's supervisor or ui take a bit longer
  
  launch_and_wait 5 back front
  wait_for_service back 3300 'RAGE Analytics Backend'
  wait_for_service front 3350 'RAGE Analytics Frontend'
  
  recho " * use '$0 logs <service>' to inspect service logs"
  recho " * use '$0 status' to see status of all services"
  recho "output of '$0 status' follows:"
  display_status
}

# stop containers
function stop() {
  recho "       Stopping containers"
  recho "-------------------------------"
  show_and_do ${COMPOSE_COMMAND} stop
}

# force-stop and purge containers
function purge() {
  recho "       Purging containers"
  recho "-------------------------------"
  show_and_do ${COMPOSE_COMMAND} kill 
  show_and_do ${COMPOSE_COMMAND} rm -f -v 
  recho "(you may need root permissions to empty the data volume)"
  sudo rm -r data/* \
    && recho "data volume emptied"
}

# uninstall: remove images; optionally nuke all docker
function uninstall() {
  RAGE_IMAGES=$(docker images -q 'eucm/*')
  if [ -z "$RAGE_IMAGES" ] ; then
    recho "no RAGE images to remove."
  else 
    recho "       Removing images"
    recho "-------------------------------"
    show_and_do docker rmi $RAGE_IMAGES
  fi
  # prompt for total uninstall
  read -p "Also remove ALL (non-RAGE) containers and images? [y/N] " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]] ; then
    # Delete all containers
    show_and_do docker rm $(docker ps -a -q)
    # Delete all images
    show_and_do docker rmi $(docker images -q)  
  fi
}

# display container status
function display_status() {
  recho "       Container status"
  recho "-------------------------------"
  show_and_do ${COMPOSE_COMMAND} ps
}

# display logs of a container
function display_logs() {
  recho "       Logs for $1 (Ctrl+C to exit)"
  recho "-------------------------------"
  show_and_do ${COMPOSE_COMMAND} logs $1
}

# enter into shell for a given container name
function shell_into() {
  recho "       Displaying bash shell for $1 (enter 'exit' to exit)"
  recho "-------------------------------"
  show_and_do ${DOCKER_CMD} exec -it ${CONTAINERS[$1]} /bin/bash
}

# start containers by id
function start_ids() {
  recho "       Starting containers: $@"
  recho "-------------------------------"
  show_and_do ${COMPOSE_COMMAND} up ${COMPOSE_UP_FLAGS} $@
}

# stop containers by id
function stop_ids() {
  recho "       Stopping containers: $@"
  recho "-------------------------------"
  show_and_do ${COMPOSE_COMMAND} stop $@
}

# display networking info
function network() {
  recho "       Displaying network information"
  recho "-------------------------------"
  docker_map  
  while read -r LINE ; do
    LONG_HASH=${LINE%% *}
    HASH="x${LONG_HASH:0:12}"
    echo ${LINE} | sed -e "s/[a-f0-9]*/${CONTAINERS[$HASH]}/"
  done < <( docker network inspect ${COMPOSE_NET_NAME} \
    | grep -E '([a-f0-9]+["]: {$)|(IPv4)' \
    | xargs -n 4 | sed -e 's/:.*: / /;s:/.*,::' \
  )
}

# builds a report-file, which can be used to help resolve issues
function report() {
  REPORT_FILE="report-$(date -Iminutes | sed -e "s/[:T-]/_/g;s/[+].*//").txt"

  recho "      Generating ${REPORT_FILE}"
  recho "-------------------------------"
  
  recho " ... adding your docker and docker-compose versions"
  echo "[Docker and Docker-compose versions]" > ${REPORT_FILE}
  docker -v >> ${REPORT_FILE}
  docker-compose -v >> ${REPORT_FILE}
  
  recho " ... adding hashes of local rage-*.sh scripts and *.yml file"
  echo "[Script and .yml versions]" >> ${REPORT_FILE}
  sha1sum rage-*.sh *.yml >> ${REPORT_FILE}
  
  for F in *.yml ; do 
    recho " ... adding ${F} file"
    echo "[Contents of ${F}]" >> ${REPORT_FILE}
    cat ${F} >> ${REPORT_FILE}
  done
  
  recho " ... adding kernel version and linux distribution string"
  echo "[Kernel and distro]" >> ${REPORT_FILE}
  uname -a >> ${REPORT_FILE}
  cat /etc/lsb-release >> ${REPORT_FILE}
  
  recho " ... adding partial username / group information"
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
  ${COMPOSE_COMMAND} ps >> ${REPORT_FILE}
  
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
  recho " file issues at ${PROJECT_ISSUE_URL}"
  recho " including ${REPORT_FILE} as an attachment"
}

# entrypoint
main $@
