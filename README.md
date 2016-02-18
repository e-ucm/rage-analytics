# RAGE Analytics Environment

This repository contains scripts to launch and manage the (evolving) RAGE Analytics Environment.

The RAGE Analytics Environment is a key component of the [RAGE](http://rageproject.eu/) EU H2020 project 
(Realizing an Applied Game Ecosystem), in charge of providing extensible, scalable, and simple-to-manage
game analytics for applied games.

We rely on [docker](https://docs.docker.com/installation/) to modularize and simplify deployment; and on [docker-compose](https://docs.docker.com/compose/) to manage and orchestrate (or, dare I say, _compose_) those containers. 

## Hardware and Software Requirements

In theory:

- anywhere with docker v1.7 (or greater) and docker-compose v1.4.2 (or greater) installed 
- >=12 Gb free HDD space, 4 Gb RAM. Note that one of the services, MongoDB, requires 3.4 Gb free HDD space to run.

Our testing environment:
          
- ubuntu 14.04 and 14.10 x64, both stand-alone and running in VirtualBox VMs under Windows hosts
- docker v1.9, docker-compose v1.5
- >=12 Gb free HDD space, 8 Gb RAM

## Simple usage

0. Open a shell in a recent linux (we use Ubuntu 14.04+). You must be root (`sudo su -`) unless you already have `docker` running and a compatible version of `docker-compose` installed 
1. Download the launch script: `wget https://raw.githubusercontent.com/e-ucm/rage-analytics/master/rage-analytics.sh`
2. Mark the script as executable, and launch it: `chmod +x rage-analytics.sh && ./rage-analytics.sh launch` (note that it requires `bash` to run). Besides `launch`, the scripts accepts several other commands - use `./rage-analytics.sh --help` to see their names and descriptions.
3. follow the instructions in the [Quickstart guide](https://github.com/e-ucm/rage-analytics/wiki/Quickstart) to learn more 

... and type `./rage-analytics status` to check that everything has been launched. Expected output:

```
     Name                    Command               State                    Ports                  
--------------------------------------------------------------------------------------------------
a2                npm run docker-start             Up       0.0.0.0:3000->3000/tcp                 
back              npm run docker-start             Up       0.0.0.0:3300->3300/tcp                 
elastic           /docker-entrypoint.sh elas ...   Up       9200/tcp, 9300/tcp                     
front             npm run docker-start             Up       0.0.0.0:3350->3350/tcp                 
gamestorage       npm run docker-start             Up       0.0.0.0:3400->3400/tcp                 
kzk               supervisord -n                   Up       2181/tcp, 9092/tcp                     
lrs               ./run.sh                         Up       0.0.0.0:8180->8080/tcp                 
mongo             /entrypoint.sh mongod            Up       27017/tcp                              
nimbus            /bin/sh -c ./goStorm.sh nimbus   Up       0.0.0.0:6627->6627/tcp                 
rage_realtime_1   /bin/sh -c cp ${OUTPUT_JAR ...   Exit 0                                          
redis             /entrypoint.sh redis-server      Up       6379/tcp                               
supervisor        /bin/sh -c ./goStorm.sh su ...   Up       6700/tcp, 6701/tcp, 6702/tcp, 6703/tcp 
ui                /bin/sh -c ./goStorm.sh ui       Up       0.0.0.0:8081->8081/tcp 
```

The following services will be launched:
* `a2` at `http://your-ip:3000`: running [Authentication&Authorization](https://github.com/e-ucm/a2) server. Allows registering server-side applications (such as the `rage-analytics-backend`) 
* `back` at `http://your-ip:3300`: the [Analytics Back-end](https://github.com/e-ucm/rage-analytics-backend) server. Previously known as Gleaner-backend
* `front` at `http://your-ip:3350`: the [Analytics Front-end](https://github.com/e-ucm/rage-analytics-frontend) server. Previously known as Gleaner-frontend

Other servers, exposed by default but which would be firewalled of in a production deployment, include
* OpenLRS at `http://your-ip:8180`
* Storm UI at `http://your-ip:8081`

Exposed ports can be easily altered by modifying `docker-compose.yml` (eg.: changing the `ui` port to `8082:8081`) would expose `nimbus-ui` in `8082` instead of its currently exposed port, `8081`.

## Troubleshooting

The `report` command generates a text file with information that can help us diagnose any problems during installation or execution. It does not include any personally-identifiable [information](https://github.com/e-ucm/rage-analytics/blob/master/rage-analytics.sh) (in particular, neither your machine's public IP  nor your username is included; although we do want to know if you are running it as root or using a `docker` group).

When you have a problem,

- run `./rage-analytics.sh report` (_before_ stopping the services)
- open an issue on our [issues page](https://github.com/e-ucm/rage-analytics/pulls) (if you register as a user on github, you will be e-mailed as soon as we comment on the issue)
- append the report to your new issue, describe the problem and the steps to reproduce it as accurately as possible. We will get back to you as soon as we can.

## Under the hood

To rebuild a particular image, checkout the images' source with git, change whatever files you fancy, and then,

1. rebuild the image, and tag it as the service you are replacing via `docker build -t <image-tag> <dockerfile-location>`
2. stop the affected service: `./rage-analytics.sh stop <id>` 
3. start the affected service, using the new version: `./rage-analytics.sh start <id>` 

Example: the following statements would rebuild `rage-analytics-backend`
```
  git clone https://github.com/e-ucm/rage-analytics-backend
  # ... change stuff
  docker build -t eucm/rage-analytics-backend rage-analytics-backend
  ./rage-analytics.sh restart
```
