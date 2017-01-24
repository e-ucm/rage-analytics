# RAGE Analytics Environment

This repository contains scripts to launch and manage the (evolving) RAGE Analytics Environment.

The RAGE Analytics Environment is a key component of the [RAGE](http://rageproject.eu/) EU H2020 project 
(Realizing an Applied Game Ecosystem), in charge of providing extensible, scalable, and simple-to-manage
game analytics for applied games.

We rely on [docker](https://docs.docker.com/installation/) to modularize and simplify deployment; and on [docker-compose](https://docs.docker.com/compose/install/) to manage and orchestrate (or, dare I say, _compose_) those containers. 

We usually require the [latest version of docker](https://github.com/docker/docker/releases) and a specific version of docker-compose. To see what docker-compose version we specifically require for the platform to work, check out the [rage-analytics.sh](https://github.com/e-ucm/rage-analytics/blob/master/rage-analytics.sh#L23) file. For instalation, execute the following commands:

          curl -L https://github.com/docker/compose/releases/download/[INSTALL_COMPOSE_VERSION]/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
          chmod +x /usr/local/bin/docker-compose
         
Where `[INSTALL_COMPOSE_VERSION]` is the version we require of docker-compose in the [rage-analytics.sh](https://github.com/e-ucm/rage-analytics/blob/master/rage-analytics.sh#L23) file. For instance, if we currently require `INSTALL_COMPOSE_VERSION='1.7.1'`, the command should be:         

          curl -L https://github.com/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
          chmod +x /usr/local/bin/docker-compose

## Hardware and Software Requirements

In theory, only requirements are:

- docker installed, minimum required version specified in the [rage-analytics.sh](https://github.com/e-ucm/rage-analytics/blob/master/rage-analytics.sh#L21) file
- docker-compose installed, required version specified in the [rage-analytics.sh](https://github.com/e-ucm/rage-analytics/blob/master/rage-analytics.sh#L23) file
- Hardware:
    * More then 12 Gb free HDD space (Note that one of the services, MongoDB, requires 3.4 Gb free HDD space to run)
    * 4 Gb of RAM
    * 2 CPU cores for avoiding bottlenecks

Our testing environment:
          
- ubuntu 14.04, 14.10 x64 and 16.04.1 x86_64, all stand-alone and running in VirtualBox VMs under Windows hosts
- docker v1.13.0, build 49bf474
- docker-compose v1.7.1 build 0a9ab35
- Hardware:
    * 20 GB free HDD space
    * 8 GB of RAM
    * 3 CPUs @ 2.2 GHz

## Simple usage

Note that before we can start using the system, we must execute the following command in Linux based systems: `sudo sysctl -w vm.max_map_count=262144`. More info can be found at the official 
ElasticSearch configuration (documentation)[https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration.html#vm-max-map-count].

0. Open a shell in a recent linux (we use Ubuntu 14.04+). You must be root (`sudo su -`) unless you already have `docker` running and a compatible version of `docker-compose` installed 
1. Download the launch script: `wget https://raw.githubusercontent.com/e-ucm/rage-analytics/master/rage-analytics.sh`
2. Mark the script as executable, and launch it: `chmod +x rage-analytics.sh && ./rage-analytics.sh launch` (note that it requires `bash` to run). Besides `launch`, the scripts accepts several other commands - use `./rage-analytics.sh --help` to see their names and descriptions.
3. follow the instructions in the [Quickstart guide](https://github.com/e-ucm/rage-analytics/wiki/Quickstart) to learn more 

... and type `./rage-analytics.sh status` to check that everything has been launched. Expected output:

```
     Name                    Command               State                        Ports                      
----------------------------------------------------------------------------------------------------------
a2                npm run docker-start             Up       0.0.0.0:3000->3000/tcp                         
back              npm run docker-start             Up       0.0.0.0:3300->3300/tcp                         
elastic           /docker-entrypoint.sh elas ...   Up       0.0.0.0:9217->9217/tcp, 0.0.0.0:9317->9317/tcp 
elastic5          /docker-entrypoint.sh elas ...   Up       0.0.0.0:9200->9200/tcp, 0.0.0.0:9300->9300/tcp 
front             npm run docker-start             Up       0.0.0.0:3350->3350/tcp                         
gamestorage       npm run docker-start             Up       0.0.0.0:3400->3400/tcp                         
kibana            /docker-entrypoint.sh kibana     Up       0.0.0.0:5601->5601/tcp                         
kzk               supervisord -n                   Up       0.0.0.0:2181->2181/tcp, 0.0.0.0:9092->9092/tcp 
lrs               ./run.sh                         Up       0.0.0.0:8180->8080/tcp                         
mongo             /entrypoint.sh mongod            Up       0.0.0.0:27017->27017/tcp                       
nimbus            /bin/sh -c ./goStorm.sh nimbus   Up       0.0.0.0:6627->6627/tcp                         
rage_realtime_1   /usr/local/bin/mvn-entrypo ...   Exit 0                                                  
redis             docker-entrypoint.sh redis ...   Up       6379/tcp                                       
supervisor        /bin/sh -c ./goStorm.sh su ...   Up       6700/tcp, 6701/tcp, 6702/tcp, 6703/tcp 
```

The following services will be launched:
* `a2` at `http://your-ip:3000`: running [Authentication&Authorization](https://github.com/e-ucm/a2) server. Allows registering server-side applications (such as the `rage-analytics-backend`) 
* `back` at `http://your-ip:3000/api/proxy/gleaner/`: the [Analytics Back-end](https://github.com/e-ucm/rage-analytics-backend) server. Previously known as Gleaner-backend
* `front` at `http://your-ip:3000/api/proxy/afront/`: the [Analytics Front-end](https://github.com/e-ucm/rage-analytics-frontend) server. Previously known as Gleaner-frontend

Other servers, exposed by default but which would be firewalled of in a production deployment, include
* OpenLRS at `http://your-ip:8180`
* Storm UI at `http://your-ip:8081`

Exposed ports can be easily altered by modifying `docker-compose.yml` (eg.: changing the `ui` port to `8082:8081`) would expose `nimbus-ui` in `8082` instead of its currently exposed port, `8081`.

The following diagram displays the launch order of the containers as well as the dependencies between them.

![docker containers and dependencies in rage-analytics](https://cloud.githubusercontent.com/assets/5658058/14140714/fb5b18d8-f67a-11e5-9b9c-41efd9277ee1.png)

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

## Understanding the RAGE Analytics data flow

We highly recommend reading [Understanding-RAGE-Analytics-Traces-Flo](https://github.com/e-ucm/rage-analytics/wiki/Understanding-RAGE-Analytics-Traces-Flow) for a deep comprehension of how the data (traces) are being moved through the RAGE Analytics infrastructure, from the student playing the game (client side tracker) to thetracher viewing the dashboards (Kibana visualizations) in real time.


