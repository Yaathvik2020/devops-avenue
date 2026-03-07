variable "region" {
type = string
default = "us-east-2"
description = "AWS region"
}

#provide your key name
variable "key_pair" {
  description = "The name of the key pair to use for EC2 instances"
  default = "demo-devops-avenue-ue2"
  type        = string
}

variable "tags" {
type = map(string)
default = {
    terraform  = "true"
    demo = "istio"
}
description = "Tags to apply to all resources"
}

variable "node_name" {
  default = "istio-demo"
}

variable "cluster_node_type" {
type = string
default = "t2.xlarge" # x large might not be enough with a bunch of pods
}