#!/bin/bash
set -e

LE_ACCOUNT_EMAIL=${1?"Please specify an email address for the letsencrypt account"}
DNS_DOMAIN=$(terraform output --raw dns_domain)

kubectl apply -k cluster-resources/crds/

kubectl kustomize cluster-resources/ | \
    sed s/LE_ACCOUNT_EMAIL/${LE_ACCOUNT_EMAIL}/g | \
    sed s/DNS_DOMAIN/${DNS_DOMAIN}/g | \
    kubectl apply -f -
