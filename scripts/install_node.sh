#!/bin/bash

# Needed for CSI on DO to work properly.
# https://github.com/digitalocean/csi-digitalocean/issues/297#issuecomment-619338495
DO_RULES=/etc/udev/rules.d/99-digitalocean-automount.rules
if [ -f $${DO_RULES} ] ; then
  echo "Removing $${DO_RULES}"
  rm -f $${DO_RULES}
fi

# Install container runtime
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/
# https://github.com/containerd/containerd/blob/main/docs/getting-started.md

## containerd as systemd service
wget -q https://github.com/containerd/containerd/releases/download/v1.6.6/containerd-1.6.6-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-1.6.6-linux-amd64.tar.gz
mkdir -p /usr/local/lib/systemd/system
wget -q -O /usr/local/lib/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
mkdir -p /etc/containerd
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' > /etc/containerd/config.toml
systemctl daemon-reload
systemctl enable --now containerd

## runc
wget -q -O /usr/local/sbin/runc https://github.com/opencontainers/runc/releases/download/v1.1.3/runc.amd64
chmod a+x /usr/local/sbin/runc

## CNI plugins
wget -q https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz

## nerdctl (optional)
wget -q https://github.com/containerd/nerdctl/releases/download/v0.22.0/nerdctl-0.22.0-linux-amd64.tar.gz
tar Cxzvf /usr/local/bin nerdctl-0.22.0-linux-amd64.tar.gz

# Configure kernel
modprobe br_netfilter
echo '1' > /proc/sys/net/ipv4/ip_forward

# Install K8s
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
add-apt-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"
apt-get update
apt-get install -y kubelet=${k8s_version}-00 kubeadm=${k8s_version}-00 kubectl=${k8s_version}-00
apt-mark hold kubelet kubeadm kubectl

kubeadm config images pull

%{ if provider == "aws" }
# The AWS cloud provider needs this. :(
NODE_NAME=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
%{ else }
NODE_NAME=${host_name}
%{ endif }

cat > kubeadmconf.yaml << EOCONF
${kubeadmconf}
EOCONF

%{ if is_initial }

kubeadm init --config kubeadmconf.yaml --upload-certs |tee kubeadm.log

JOIN_TOKEN=$(grep 'Using token:' kubeadm.log |cut -f 4 -d" ")
CERT_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
            openssl rsa -pubin -outform der 2>/dev/null | \
            openssl dgst -sha256 -hex | sed 's/^.* //')
CERT_KEY=$(grep -A1 'Using certificate key:' kubeadm.log |tail -n1)

cat > join_vars.tfvars <<EOF
join_token = "$${JOIN_TOKEN}"
cert_hash  = "sha256:$${CERT_HASH}"
cert_key   = "$${CERT_KEY}"
EOF
cp /etc/kubernetes/admin.conf / && chmod a+r /admin.conf

%{ else }

kubeadm join --config kubeadmconf.yaml

%{ endif }
