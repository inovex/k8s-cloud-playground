#!/bin/bash
set -e

SSH_USER=${1?"Please specify ssh user name"}

CP_ENDPOINT="https://$(terraform output --raw cp_endpoint_ip):6443/"
echo "Control Plane Endpoint: ${CP_ENDPOINT}"
while ! (curl -sk --connect-timeout 10 ${CP_ENDPOINT} 2>&1 >/dev/null) ; do
    echo "Waiting for endpoint to become available."
    sleep 5
done

INITIAL_MASTER_IP=$(terraform output --raw initial_master_ip)
echo "Initial Master IP: ${INITIAL_MASTER_IP}"

echo "Retrieving config from initial master."
scp ${SSH_USER}@${INITIAL_MASTER_IP}:/admin.conf .
scp ${SSH_USER}@${INITIAL_MASTER_IP}:/join_vars.tfvars .

echo "Installing Weave networking."
kubectl --kubeconfig admin.conf apply \
    -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

echo "Waiting for nodes to become ready."
kubectl --kubeconfig admin.conf wait --for=condition=Ready node --all

echo
echo "Now run this command to create and join more nodes:"
echo
echo "  terraform apply -var-file=join_vars.tfvars"
