#!/usr/bin/env bash
set -euo pipefail
[[ "${DEBUG:-false}" == "true" ]] && set -x

rsync -avh /vagrant/ /home/vagrant/rage-analytics/
cd /home/vagrant/rage-analytics
if [[ ! -e "/home/vagrant/rage-analytics/impress-initialized" ]]; then
  ./formalz.sh
  touch /home/vagrant/rage-analytics/impress-initialized
fi