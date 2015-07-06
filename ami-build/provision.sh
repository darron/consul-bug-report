#!/bin/bash
apt-get clean
apt-get update
apt-get -y upgrade

apt-get -y install curl dnsmasq stress cpulimit rand

echo 'server=/consul/127.0.0.1#8600' > /etc/dnsmasq.d/10-consul

service dnsmasq restart

cd /usr/local/bin
curl -s http://stedolan.github.io/jq/download/linux64/jq > jq
curl -s https://raw.githubusercontent.com/octohost/octohost-cookbook/master/files/default/consulkv > consulkv
chmod a+x jq consulkv

curl -s https://packagecloud.io/install/repositories/darron/consul/script.deb.sh | sudo bash
curl -s https://packagecloud.io/install/repositories/darron/consul-webui/script.deb.sh | sudo bash
curl -s https://packagecloud.io/install/repositories/darron/consul-template/script.deb.sh | sudo bash

apt-get -y install consul consul-template consul-webui

mkdir -p /var/lib/consul
mkdir -p /etc/consul.d/

mkdir -p /usr/local/bin
cat > /usr/local/bin/stress.sh <<EOF
#!/bin/bash
NUMBER=\$(rand -M 90)
stress -c 1 &
sleep 3
PROCESS_ID=\$(pidof -o \$! stress)
cpulimit -p \$PROCESS_ID -l \$NUMBER
EOF
chmod a+x /usr/local/bin/stress.sh

cat > /usr/local/bin/destress.sh <<EOF
#!/bin/bash
pkill stress
pkill cpulimit
EOF
chmod a+x /usr/local/bin/destress.sh

cat > /etc/consul.d/stress.json <<EOF
{
  "watches": [
    {
      "type": "event",
      "name": "stress",
      "handler": "sudo /usr/local/bin/stress.sh"
    },
    {
      "type": "event",
      "name": "destress",
      "handler": "sudo /usr/local/bin/destress.sh"
    }
  ]
}
EOF
