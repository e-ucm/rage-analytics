# RAGE Analytics Environment

This repository contains scripts to launch and manage the (evolving) RAGE Analytics Environment.

The RAGE Analytics Environment is a key component of the [RAGE](http://rageproject.eu/) EU H2020 project 
(Realizing an Applied Game Ecosystem), in charge of providing extensible, scalable, and simple-to-manage
game analytics for applied games.

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

## Further information
For more details, check out the [RAGE Analytics wiki page](https://github.com/e-ucm/rage-analytics/wiki).
