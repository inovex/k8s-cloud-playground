#!/bin/bash
set -e

SSH_USER=${1?"Please specify ssh user name"}

PROXY_IP=$(terraform output --raw ingress_ip)

echo "Uploading updated haproxy.cfg."
cat > /tmp/haproxy.cfg <<EOCFG
$(terraform output --raw haproxycfg)
EOCFG

scp /tmp/haproxy.cfg ${SSH_USER}@${PROXY_IP}:/tmp/haproxy.cfg
ssh ${SSH_USER}@${PROXY_IP} sudo mv /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg
ssh ${SSH_USER}@${PROXY_IP} sudo systemctl restart haproxy.service
