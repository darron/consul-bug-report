#!/bin/bash

DD_API_KEY=put-your-API-key-here bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/dd-agent/master/packaging/datadog-agent/source/install_agent.sh)"
sudo cat > /tmp/consul.yaml <<EOF
init_config:

instances:
    - url: http://localhost:8500
      catalog_checks: yes
      new_leader_checks: yes
EOF
cd /tmp
curl -s https://gist.githubusercontent.com/darron/9a4ac7ada310744dec1a/raw/a2699de2e67841b919328241a27d763e5e4500bb/consul.py > consul.py
sudo mv -f /tmp/consul.yaml /etc/dd-agent/conf.d/consul.yaml
sudo mv -f /tmp/consul.py /etc/dd-agent/checks.d/consul.py
sudo service datadog-agent restart
