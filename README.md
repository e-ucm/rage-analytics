# IMPRESS project specific branch

Included in this branch there is everything needed to deploy a rage-analytics framework with everything needed to manage the [IMPRESS Project](https://impress-project.eu/) activities, in particular FormalZ activities.

## Demo / simple installation

This repository contains all required files to setup a demo / simple installation using [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/). So, before continuing you need to install in your machine:

- [VirtualBox](https://www.virtualbox.org/). The installation has been tested with VirtualBox 6.X.
- [Vagrant](https://www.vagrantup.com/). The installation has been tested with vagrant 2.2.X.

Once these tools are installed, then you need copy of this branch of the repository. You can either:
1. Clone this repository and checkout the `impress` branch.
```
git clone https://github.com/e-ucm/rage-analytics/
git checkout -b impress
```
2. Download a IMPRESS release from the [GitHub's project release page](https://github.com/e-ucm/rage-analytics/releases).

 Once downloaded, you need to:

3. Open a terminal.
4. Change your current directory to the directory where you downloaded the project.
5. Run `vagrant up`.

This last step will take a while, once finished you can access [http://localhost:3000/api/proxy/afront/](http://localhost:3000/api/proxy/afront/) and start creating your own users.

> Note: For FormalZ activities, you do not need to do anything else because you can access FormalZ's activities analytics dashboards directly from FormalZ UI.

## Custom installation (FormalZ only)

It is **HIGHLY RECOMMENDED** to modify the file **formalz.sh**. At the beginning of the document there are some configuration parameters that should be personalized. These config include:
* **developeruser**: the username of the admin/developer username.
* **developeremail**: its email.
* **developerpass**: its password.
* **domain**: The domain name where the analytics framework is hosted.

### Installation

**docker and docker-compose need to be installed.**

There is no need to modify docker-compose.yml or to run ./rage-analytics.sh.

There is **only one step**: ./formalz.sh

## Additional utils included

There is included in this repository a folder called **utils**. In this folder there is a PHP file that includes a simple API to manage the framework simply through the webhook.

Additionally a trace sender is included in a folder. The trace sender uses anonymous users so, if anonymous users are not enabled in the activity, it will not work unless modified for login up the user.

## RAGE Analytics Environment

If you want to customize the installation go to [main branch](https://github.com/e-ucm/rage-analytics) of the project.

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