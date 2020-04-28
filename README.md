Kubernetes Cloud Playground
===========================

# Introduction

This repository is my playground for trying out Kubernetes beyond minikube. Also, I like Terraform a lot so I am using that, also trying out some of the new 0.12 features.

## Goals

  * Easily start a Kubernetes cluster that is more production-like than minikube.
  * Learn all about the anatomy and the details of how to setup a Kubernetes cluster with kubeadm.
  * Be able to launch multiple control plane and worker nodes to see how HA really works.
  * Try out cloud provider features like remote volumes and load balancers.
  * Maybe be able to do some load testing?
  * Try out new cloud providers besides my standard AWS.

## Non-Goals

  * Have a system that produces a production-ready cluster.
  * Have a system that works out-of-the-box -> some coding required.

I am releasing this as a learning tool so that maybe it can help others learn Kubernetes in detail. You are encouraged to read and understand all of the code, especially [the script that installs the nodes](scripts/install_node.sh) and the kubeadm configs in the same directory. That is also where you will make changes if you want to configure your cluster differently.

# Cluster Deployment

## Multiple Cloud Providers

This repository has Terraform code for both AWS and Digitalocean. I have yet to complete my journey into GCP which seems to do a lot of things differently.

I had originally thought to be able to start clusters in multiple clouds in parallel and that goal is not far off. Currently though, I can only switch fairly easily between the two implementations. The top-level configuration is intended to be generic and the installed clusters should be almost identical.

I am using a cloud-based load balancer for the API servers, to be more production-like. The DO code also has a load balancer for ingress because I was doing some ingress experiments there. It should not be too hard to create another LB in AWS but I also might want to look into dynamic provisioning via the cloud-controller.

## Prerequites

  * Install terraform 0.12
  * Install kubectl in the version you plan your cluster to have.
  * Make sure you have bash, curl and ssh installed.

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
     * Adapt `project_name` if you feel like it. It will create a project of this name in DO and be used as a prefix for names in AWS (so it should not be too long). Also, this will be the name of the cluster.
     * Configure sensible `admin_cidrs` for the network you are sitting in. You can simply use your [current.public.IP.address](https://www.whatsmyip.org/)/32 , e.g. 123.123.123.123/32, or use a broader range if it might get reassigned dynamically.
     * Choose the size of your cluster by commenting out some of the nodes from the example. It might be a good idea to start with 1 master and 1 worker. You can change the cluster size anytime later. VM sizes are defined in [do/data.tf](do/data.tf) and [aws/data.tf](aws/data.tf).
  2. Edit `clusters.tf` to comment out the cluster you would like to start: `do_cluster` or `aws_cluster`. Also check if the `region` is suitable for you. The AWS cluster has an extra `owner_tag` parameter because it will add an `Owner` tag to most resources. Useful if, like in my case, you are sharing the AWS account.
  3. Edit `outputs.tf` and uncomment the outputs from the cluster you are using. The `init_cluster.sh` script depends on these. I could have done some `try()` trickery here, I guess.

## Deploy the cluster

Initialize Terraform and deploy the initial master and run `kubeadm init` on it.

    terraform init
    terraform apply -var init_phase=true

Once this has finished, you *could* follow the installation logs on the initial master. On DO the user is `root`, on AWS it is `ubuntu`.

    DO:  ssh root@$(terraform output initial_master_ip) tail -f /var/log/cloud-init-output.log
    AWS: ssh ubuntu@$(terraform output initial_master_ip) sudo tail -f /var/log/cloud-init-output.log

After that, the local `init_cluster.sh` script will download the `admin.conf` and the data needed for other nodes to join the cluster. It will also install Weave networking on the cluster. With this, you can already access the cluster.

    DO:  ./init_cluster.sh root
    AWS: ./init_cluster.sh ubuntu
    export KUBECONFIG=$(pwd)/admin.conf
    kubectl get nodes

Finally, you can create and join the other nodes configured in your `terraform.tfvars`:

    terraform apply -var-file=join_vars.tfvars

# Play with the cluster

## Install cluster resources

Some basic resources for the DO cluster: CSI driver, snapshot controller, ingress controller:

    copy do_token cluster-resources/storage-do/access-token
    kubectl apply -k cluster-resources/do-base
    kubectl apply -k cluster-resources/do-base  # Wonder when CRD deployment will work without a race condition.

Some basic resouces for the AWS cluster: CSI driver, snaphot controller

    kubectl apply -k cluster-resources/aws-base
    kubectl apply -k cluster-resources/aws-base  # CRDs ...

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