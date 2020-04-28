variable "project_name" {
  type    = string
}

variable "ssh_keys" {
  type = list(string)
}

variable "region" {
  type    = string
  default = "europe-west3"
}

variable "k8s_version" {
  type        = string
  description = "Kubernetes version to install. Upgrades are not supported this way."
}

variable "kubeadmconf" {
  type        = string
  default     = "default"
  description = "Use different kubeadmconfig-<name>.yaml."
}

variable "init_phase" {
  type        = bool
  default     = false
  description = "If true, only one node ist brought up to run 'kubeadm init' on it."
}

variable "initial_master" {
  type        = string
  description = "The master which is to run 'kubadm init' during init phase."
}

variable "join_token" {
  type        = string
  default     = ""
  description = "The token needed for a node to join the cluster"
}

variable "cert_hash" {
  type        = string
  default     = ""
  description = "The hash of the API server's cert."
}

variable "cert_key" {
  type        = string
  default     = ""
  description = "The key to retrieve certs from the cluster."
}

variable "admin_cidrs" {
  type        = list(string)
  description = "IP addresses to allow SSH access from."
}

variable "masters" {
  type = map(object({
    size = string
  }))
}

variable "workers" {
  type = map(object({
    size = string
  }))
}
