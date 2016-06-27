# High-level browser-based test battery for Rage Analytics

This folder contains tests intended to be executed using protractor, once selenium webdriver is running:

## Steps to setup tests:

These instructions have been tested on newer Ubuntu distributions (14.04 and 16.04).

- install node.js: see [here](https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions)
- install protractor and webdriver:

    sudo npm install -g protractor
    sudo webdriver-manager install
    sudo webdriver-manager update

## Steps to run tests

Make sure that the webdriver is running:

    sudo webdriver-manager start

Launch the tests from within the `test` folder:

    protractor conf.js 
    
## If tests fail

Copy and paste the output and send it to the developers, together with the output of `./rage-analytics.sh report`