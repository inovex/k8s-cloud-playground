Kubernetes Cloud Playground
===========================

# Introduction

This repository is my playground for trying out Kubernetes beyond minikube. Also, I like Terraform a lot so I am using that.

## Goals

  * Easily start a Kubernetes cluster that is more production-like than minikube.
  * Learn all about the anatomy and the details of how to setup a Kubernetes cluster with kubeadm.
  * Be able to launch multiple control plane and worker nodes to see how scheduling and HA really work.
  * Try out cloud provider features like block volumes and load balancers.
  * Maybe be able to do some load testing?
  * Try out new cloud providers besides my standard AWS.

## Non-Goals

  * Have a system that produces a production-ready cluster.
  * Have a system that works out-of-the-box -> some coding required.

I am releasing this as a learning tool so that maybe it can help others learn Kubernetes in detail. You are encouraged to read and understand all of the code, especially [the script that installs the nodes](scripts/install_node.sh) and the kubeadm configs in the same directory. That is also where you will make changes if you want to configure your cluster differently.

# Cluster Deployment

## Multiple Cloud Providers

This repository deploys the cluster in the ICS (inovex Cloud Service), the Openstack-based cloud for inovex in-house use. It may therefore make some assumptions about the Openstack installation (e.g. flavor names) but I expect it should not be too hard to deploy to any other Openstack cloud. Services used to my knowledge are Keystone, Nova, Neutron, Cinder and Horizon. No load balancer service is available, though, so this implementation comes with a haproxy (without HA, though).

This repository has also Terraform code for AWS and Digitalocean. The original idea was to easily switch deployment between different clouds but ICS/Openstack has been given the most attention in the latest update such that AWS and DO are probably broken in this version.

## Prerequites

  * Install terraform 1.x
  * Install kubectl in the version you plan your cluster to have.
  * Make sure you have bash, curl and ssh installed.

### ICS

  1. Place a `clouds.yaml` in the root directory that allows access to a cloud named `ics`.
  2. In the Horizon UI create application credentials for the cinder CSI driver.
  3. Go to `cluster-resources/csi-cinder` and cop `sample-cloud.conf` to `cloud.conf` and fill in the values from the application credentials.

### Digitalocean

  1. Go to [Account -> API](https://cloud.digitalocean.com/account/api/tokens) and generate a personal access token. Save it locally as e.g. `do_token`. (Feel free to use gpg to encrypt it at rest.)
  2. Go to [Account -> Settings -> Security](https://cloud.digitalocean.com/account/security) and upload your SSH public key.
  3. See the [Terraform provider documentation](https://www.terraform.io/docs/providers/do/index.html). On your command line, place the token in an environment variable `DIGTIALOCEAN_TOKEN`:

    export DIGTIALOCEAN_TOKEN=$(cat do_token)

### AWS

  1. Generate and download credentials for an IAM user with Administrator privileges.
  2. Create an EC2 keypair with your public SSH key.
  3. See the [Terraform provider documentation](https://www.terraform.io/docs/providers/aws/index.html).
     * Create a local profile for this user and do `export AWS_PROFILE=myprofile`.
     * Alternatively you can set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` directly.

## Configure the deployment

  1. Copy `terraform-example.tfvars` to `terraform.tfvars`.
     * Replace `my-key` with the name of your SSH key. DO supports multiple keys, that's why this is a list.
     * Adapt `project_name`. For the ICS this must be your project name.
     * Configure sensible `admin_cidrs` for the network you are sitting in. You can simply use your [current.public.IP.address](https://www.whatsmyip.org/)/32 , e.g. 123.123.123.123/32, or use a broader range if it might get reassigned dynamically.
     * Choose the size of your cluster by commenting out some of the nodes from the example. It might be a good idea to start with 1 master and 1 worker. You can change the cluster size anytime later. VM sizes are defined in [ics/data.tf](ics/data.tf), [do/data.tf](do/data.tf) and [aws/data.tf](aws/data.tf).
  2. Edit `clusters.tf` to comment out the cluster you would like to start: `ics_cluster`, `do_cluster` or `aws_cluster`. Also check if the `region` is suitable for you. The AWS cluster has an extra `owner_tag` parameter because it will add an `Owner` tag to most resources. Useful if, like in my case, you are sharing the AWS account.
  3. Edit `outputs.tf` and uncomment the outputs from the cluster you are using. The `init_cluster.sh` script depends on these. I could have done some `try()` trickery here, I guess.

## Deploy the cluster

Initialize Terraform and deploy the initial master. The install script will run `kubeadm init` on it.

    terraform init
    terraform apply -var init_phase=true

Once this has finished, you *could* follow the installation logs on the initial master. The SSH_USER is `ubuntu` except on DO where it is `root`.
The ICS uses a Jump Proxy for SSH and the nodes do not have public IPs.

    ICS: ssh -J ubuntu@$(terraform output --raw cp_endpoint_ip) ubuntu@$(terraform output --raw initial_master_ip) sudo tail -f /var/log/cloud-init-output.log
    AWS: ssh ubuntu@$(terraform output --raw initial_master_ip) sudo tail -f /var/log/cloud-init-output.log
    DO:  ssh root@$(terraform output --raw initial_master_ip) tail -f /var/log/cloud-init-output.log

After that, the local `init_cluster.sh` script will download the `admin.conf` and the data needed for other nodes to join the cluster. It will also install Weave networking on the cluster. With this, you can already access the cluster.

    ICS/AWS: ./init_cluster.sh ubuntu
    DO:      ./init_cluster.sh root

    export KUBECONFIG=$(pwd)/admin.conf
    kubectl get nodes

Now you can create and join the other nodes configured in your `terraform.tfvars`:

    terraform apply -var-file=join_vars.tfvars

The haproxy load balancer on the ICS is not configured automatically, so it needs to be updated whenever the nodes change. The config has been created by Terraform because it has the IP addresses.

    ICS: ./update_proxy.sh ubuntu

# Use the cluster

## Install cluster resources

Some basic resources for the cluster will be installed:

* Nginx ingress controller
* Cert-Manager with a Let's Encrypt ClusterIssuer
* Metrics server
* Dashboard
* CSI driver (Cinder on ICS) with snapshot controller

The script needs an email address that is used for the Let's Encrypt account. Expiry notices will be sent here.

    ./install_cluster.sh email@example.com

# END OF README UPDATE

## Play with examples

In the `cluster-resources/examples` directory:

    * apps: some apps using the CSI driver and one using an ingress
    * snapshots: Try out snapshots: Take one, then create a volume from it via a PVC.
    * static-pv: I played around with static PVs a bit, these are the remnants.
    * elasticsearch: I tried to put ES in a StatefulSet using CSI volumes. The k8s part worked but I did not have to the time to dig into the Java issues.

## Play with nodes

You can add nodes to the cluster by adding them in terraform.tfvars (uncomment some from the example) and re-run terraform. Be aware, though that the join token and the uploaded certificates (for adding more masters) time out quickly (I think 24h and 1h respectively), so this should be done soon after running init. On the other hand, renewing these should be a fun exercise, too.

    terraform apply -var-file=join_vars.tfvars

To remove a worker node remove it from terraform.tfvars, then drain and remove it from the cluster before letting terraform destroy it.

    terraform drain --ignore-daemonsets gonner
    terraform delete node gonner
    terraform apply

Removing a master node is healthier when `kubeadm reset` is run on the node first so it is removed from the etcd cluster. But it might have some real-world application to know what happens when you don't do that... Note that the initial master is in no way special and it is save for the cluster to remove it (if you keep at least one other master around).

    DO:  ssh root@<exmasterip> kubeadm reset
    AWS: ssh ubuntu@<exmasterip> sudo kubeadm reset
    kubectl delete node exmaster
    terraform apply

Ugrading nodes requires terraform taints because user_data and image changes are configured to be ignored. Make the changes (size) in terraform.tfvars and run terraform taint. You could pick the node address from the terraform state. Remember to escape quotes.

    $ terraform state list |grep aws_instance
    module.aws_cluster.aws_instance.master_nodes["alpha"]
    module.aws_cluster.aws_instance.worker_nodes["delta"]
    $ terraform taint module.aws_cluster.aws_instance.worker_nodes[\"delta\"]

Enjoy the playground! :-D

# License

This project is licensed under the terms of the MIT license. See the [LICENSE](LICENSE) for details.