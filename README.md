# RAGE Analytics Environment

This repository contains scripts to launch and manage the (evolving) RAGE Analytics Environment.

The RAGE Analytics Environment is a key component of the [RAGE](http://rageproject.eu/) EU H2020 project 
(Realizing an Applied Game Ecosystem), in charge of providing extensible, scalable, and simple-to-manage
game analytics for applied games.

We rely on [docker](https://docs.docker.com/installation/) to modularize and simplify deployment; and on [docker-compose](https://docs.docker.com/compose/) to manage and orchestrate (or, dare I say, _compose_) those containers. 

## Simple usage

0. Open a shell in a recent linux (we use Ubuntu 14.04+). You must be root (`sudo su -`) unless you already have `docker` running and a compatible version of `docker-compose` installed 
1. `wget -O - https://raw.githubusercontent.com/e-ucm/rage-analytics/master/launch-all.sh | /bin/bash`

... and type `docker-compose ps` to check that everything has been launched.

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

Timing delays in `launch_all.sh` have been tested in a system with an SSD (=fast) hard disk and 8 GB RAM. You may need to increase these delays in slower systems.

To rebuild a particular image, checkout the images' source with git, change whatever files you fancy, and then,

1. stop the service if it is runing via `docker-compose kill <service-name>`
2. rebuild the image, and tag it as the service you are replacing via `docker build -t <image-tag> <dockerfile-location>`
3. relaunch the service via `docker-compose up <service-name>`

Example: the following statements would rebuild `rage-analytics-backend`
```
  git clone https://github.com/e-ucm/rage-analytics-backend
  # ... change stuff
  docker-compose kill back
  docker build -t eucm/rage-analytics-backend rage-analytics-backend
  docker-compose up back
```
