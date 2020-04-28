variable "project_name" {
  type = string
}

variable "ssh_keys" {
  type = list(string)
}

variable "region" {
  type    = string
  default = "fra1"
}

variable "kubeadmconf_file" {
  type        = string
  description = "Full path to the kubeadmconf template file."
}

variable "joinconf_file" {
  type        = string
  description = "Full path to the joinconf template file."
}

variable "template_params" {
  type        = map(string)
  description = "Common parameters for templating the kubeadmconf and joinconf."
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

variable "admin_cidrs" {
  type        = list(string)
  description = "External IP addresses to allow SSH and API access from."
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
