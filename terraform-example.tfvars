ssh_keys    = ["my-key"]         # Name of your pre-uploaded SSH key.
admin_cidrs = ["123.123.0.0/16"] # The CIDR that YOU access the cluster from.

k8s_version    = "1.18.2"
initial_master = "alpha"
kubeadmconf    = "default" # Variants of how to deploy the cluster.

masters = {
  "alpha" = {
    size = "S"
  }
  "bravo" = {
    size = "S"
  }
  "charlie" = {
    size = "S"
  }
}

workers = {
  "delta" = {
    size = "S"
  }
  "echo" = {
    size = "S"
  }
  "foxtrott" = {
    size = "S"
  }
}
# https://en.wikipedia.org/wiki/Allied_military_phonetic_spelling_alphabets