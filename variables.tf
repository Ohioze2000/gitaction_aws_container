#
variable "vpc_cidr_block"{
  type = string
  description = "VPC CIDR BLOCK"
}
variable "env_prefix"{
  type = string
  description = "ENVIRONMENT PREFIX"
}
variable "az_count" {
  default = 2
  type = number
}
variable "my_ip"{
  type = string
  description = "MY IP"
}
variable "domain_name"{
  description = "The root domain name to register (must already be registered with a registrar)"
  type        = string
}
# Add these for ECS configuration flexibility
variable "container_port" {
  type    = number
}

variable "cpu" {
  type    = string
  default = "256"
}

variable "memory" {
  type    = string
  default = "512"
}

variable "image_tag" {
  description = "The tag of the docker image to deploy (provided by GitHub Actions)"
  type    = string
  default = "latest"
}