# FORMALZ SPECIFIC BRANCH

Included in this branch there is everything needed to deploy a rage-analytics framework with everything needed to manage FormalZ activities.

It is **HIGHLY RECOMMENDED** to modify the file **formalz.sh**. At the beginning of the document there are some configuration parameters that should be personalized. These config include:
* **developeruser**: the username of the admin/developer username.
* **developeremail**: its email.
* **developerpass**: its password.
* **domain**: The domain name where the analytics framework is hosted.

## Installation

**docker and docker-compose need to be installed.**

There is no need to modify docker-compose.yml or to run ./rage-analytics.sh.

There is **only one step**: ./formalz.sh

## Additional utils included

There is included in this repository a folder called **utils**. In this folder there is a PHP file that includes a simple API to manage the framework simply through the webhook.

Additionally a trace sender is included in a folder. The trace sender uses anonymous users so, if anonymous users are not enabled in the activity, it will not work unless modified for login up the user.

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

# Patreons

A special thanks to our patreons for supporting this project:

<table>
  <tr>
    <td width="25%">
      <a href="http://rageproject.eu/" target="_blank">
        <img width="100%" src="https://cloud.githubusercontent.com/assets/19714314/23263715/60474132-f9df-11e6-8621-50f4c327bcb2.png" alt="RAGE project logo"/>
      </a>
    </td>
    <td width="25%">
      <a href="http://rageproject.eu/" target="_blank">
        <img width="100%" src="https://www.e-ucm.es/LogoH2020_RAGE.png" alt="H2020 research funding logo"/>
      </a>
    </td>
    <td width="25%">
      <a href="https://impress-project.eu/" target="_blank">
        <img width="100%" src="https://www.inesc-id.pt/wp-content/uploads/2018/01/impress_logo_703x316.png" alt="IMPRESS Logo"/>
      </a>
    </td>
    <td width="25%">
      <a href="http://erasmusplus.nl/" target="_blank">
      <img width="100%" src="https://impress-project.eu/wp-content/uploads/2017/09/eu_flag_co_funded_700x200-300x86.png" alt="Erasmus+ Program Logo"/>
    </a>
  </td>
  </tr>
</table>