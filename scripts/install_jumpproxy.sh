#!/bin/bash

# Install and configure haproxy
apt-get update
apt-get install --yes haproxy

cat > /etc/haproxy/haproxy.cfg << EOCONF
${haproxycfg}
EOCONF

systemctl restart haproxy.service
