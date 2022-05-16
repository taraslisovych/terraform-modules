variable "env" {
  default = "DEV"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "private_network_count" {
  default = 3
}

variable "public_network_count" {
  default = 3
}

variable "placement_group" {
  default = "cluster"
}
