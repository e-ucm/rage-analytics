# RAGE Analytics Environment

This repository contains scripts to launch and manage the (evolving) RAGE Analytics Environment.

The RAGE Analytics Environment is a key component of the [RAGE](http://rageproject.eu/) EU H2020 project 
(Realizing an Applied Game Ecosystem), in charge of providing extensible, scalable, and simple-to-manage
game analytics for applied games.

We rely on [docker](https://docs.docker.com/installation/) to modularize and simplify deployment; and on [docker-compose](https://docs.docker.com/compose/) to manage and orchestrate (or, dare I say, _compose_) those containers. 

## Simple usage

0. Open a shell in a recent linux (we use Ubuntu 14.04+). You must be root (`sudo su -`) unless you already have `docker` running and a compatible version of `docker-compose` installed 
1. Download the launch script: `wget https://raw.githubusercontent.com/e-ucm/rage-analytics/master/rage-analytics.sh`
2. Mark the script as executable, and launch it: `chmod +x rage-analytics.sh && ./rage-analytics.sh launch` (note that it requires `bash` to run). Besides `launch`, the scripts accepts several other commands - use `./rage-analytics.sh --help` to see their names and descriptions.
3. follow the instructions in the [Quickstart guide](https://github.com/e-ucm/rage-analytics/wiki/Quickstart) to learn more 

... and type `docker-compose ps` to check that everything has been launched. Expected output:

```
           Name                         Command               State                    Ports                  
-------------------------------------------------------------------------------------------------------------
rageanalytics_a2_1           npm run docker-start             Up       0.0.0.0:3000->3000/tcp                 
rageanalytics_back_1         npm run docker-start             Up       0.0.0.0:3300->3300/tcp                 
rageanalytics_elastic_1      /docker-entrypoint.sh elas ...   Up       9200/tcp, 9300/tcp                     
rageanalytics_front_1        npm run docker-start             Up       0.0.0.0:3350->3350/tcp                 
rageanalytics_kzk_1          supervisord -n                   Up       2181/tcp, 9092/tcp                     
rageanalytics_lis_1          mvn -Djetty.port=9090 inst ...   Up       0.0.0.0:9090->9090/tcp                 
rageanalytics_lrs_1          ./run.sh                         Up       0.0.0.0:8080->8080/tcp                 
rageanalytics_mongo_1        /entrypoint.sh mongod            Up       27017/tcp                              
rageanalytics_nimbus_1       /bin/sh -c ./goStorm.sh nimbus   Up       0.0.0.0:6627->6627/tcp                 
rageanalytics_realtime_1     /bin/sh -c cp ${OUTPUT_JAR ...   Exit 0                                          
rageanalytics_redis_1        /entrypoint.sh redis-server      Up       6379/tcp                               
rageanalytics_supervisor_1   /bin/sh -c ./goStorm.sh su ...   Up       6700/tcp, 6701/tcp, 6702/tcp, 6703/tcp 
rageanalytics_ui_1           /bin/sh -c ./goStorm.sh ui       Up       0.0.0.0:8081->8081/tcp 
```

The following services will be launched:
* `a2` at `http://localhost:3000`: running [Authentication&Authorization](https://github.com/e-ucm/a2) server. Allows registering server-side applications (such as the `rage-analytics-backend`) 
* `back` at `http://localhost:3300`: the [Analytics Back-end](https://github.com/e-ucm/rage-analytics-backend) server. Previously known as Gleaner-backend
* `front` at `http://localhost:3350`: the [Analytics Front-end](https://github.com/e-ucm/rage-analytics-frontend) server. Previously known as Gleaner-frontend
* `lis` at `http://localhost:9090/setup`: the [Lost In Space](https://github.com/e-ucm/lostinspace) server; creates analytics-enabled versions of the [LostInSpace](https://github.com/anserran/lostinspace) educational game.

Other servers, exposed by default but which would be firewalled of in a production deployment, include
* OpenLRS at `http://localhost:8080`
* Storm UI at `http://localhost:8081`

Exposed ports can be easily altered by modifying `docker-compose.yml` (eg.: changing the `ui` port to `8081:8082`) would expose `nimbus-ui` in `8082` instead of `8081`.

## Under the hood

Timing delays in `rage-analytics.sh` have been tested in a system with an SSD (=fast) hard disk and 8 GB RAM. You may need to increase these delays in slower systems.

To rebuild a particular image, checkout the images' source with git, change whatever files you fancy, and then,

1. rebuild the image, and tag it as the service you are replacing via `docker build -t <image-tag> <dockerfile-location>`
2. relaunch all services via `./rage-analytics.sh restart`

Example: the following statements would rebuild `rage-analytics-backend`
```
  git clone https://github.com/e-ucm/rage-analytics-backend
  # ... change stuff
  docker build -t eucm/rage-analytics-backend rage-analytics-backend
  ./rage-analytics.sh restart
```
