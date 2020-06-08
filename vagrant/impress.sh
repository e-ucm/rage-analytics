#!/usr/bin/env bash
set -euo pipefail
[[ "${DEBUG:-false}" == "true" ]] && set -x

rsync -avh /vagrant/ /home/vagrant/rage-analytics/
cd /home/vagrant/rage-analytics
if [[ ! -e "/home/vagrant/rage-analytics/impress-initialized" ]]; then
  ./formalz.sh
  touch /home/vagrant/rage-analytics/impress-initialized
  cd /home/vagrant/rage-analytics && ./rage-analytics.sh stop
fi

cp /vagrant/vagrant/systemd/rage-analytics.service /etc/systemd/system/rage-analytics.service
chmod 644 /etc/systemd/system/rage-analytics.service
systemctl enable rage-analytics
systemctl start rage-analytics