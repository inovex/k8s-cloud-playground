variable "project_name" {
  type = string
}

variable "ssh_keys" {
  type = list(string)
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "az_count" {
  type        = number
  default     = 3
  description = "The number of AZs to use (1-4)."

  ## Experimental feature (enable in main.tf)
  #validation {
  #  condition     = var.az_count > 0 && var.az_count <= 4
  #  error_message = "The az_count must be in the range 1-4."
  #}
}

variable "vpc_cidr" {
  type        = string
  default     = "10.10.0.0/16"
  description = "This CIDR block is sliced up into up to 4 subnets."
}

variable "owner_tag" {
  type        = string
  description = "Add this 'Owner' tag to each resource. Useful in shared AWS accounts."
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
