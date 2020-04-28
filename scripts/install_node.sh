#!/bin/bash

# Needed for CSI on DO to work properly.
# https://github.com/digitalocean/csi-digitalocean/issues/297#issuecomment-619338495
DO_RULES=/etc/udev/rules.d/99-digitalocean-automount.rules
if [ -f $${DO_RULES} ] ; then
  echo "Removing $${DO_RULES}"
  rm -f $${DO_RULES}
fi

# Install Docker CE (https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
## Set up the repository:
### Install packages to allow apt to use a repository over HTTPS
apt-get update && apt-get install -y \
  apt-transport-https ca-certificates curl software-properties-common gnupg2

### Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

### Add Docker apt repository.
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

## Install Docker CE.
apt-get update && apt-get install -y \
  containerd.io=1.2.13-1 \
  docker-ce=5:19.03.8~3-0~ubuntu-$(lsb_release -cs) \
  docker-ce-cli=5:19.03.8~3-0~ubuntu-$(lsb_release -cs)

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker


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
