variable "vpc_id" {
  type        = string # Added type
  description = "The ID of the VPC where web servers will be deployed."
}
variable "env_prefix"{
  type = string
  description = "ENVIRONMENT PREFIX"
}
variable "az_count" {
  default = 2
  type = number
  description = "The number of Availability Zones to deploy instances into."
}

# New: Required for Fargate
variable "execution_role_arn" { 
  type = string 
}
variable "task_role_arn"      { 
  type = string 
}
variable "container_image"    { 
  description = "Full ECR image URI with tag"
  type = string 
}
variable "target_group_arn"   { 
  type = string 
}
variable "alb_security_group_id" { 
  type = string 
}
variable "private_subnet_ids" { 
  type = list(string) 
}
variable "domain_name" { 
  type =  string 
}
variable "alb_listener_arn" { 
  type = string 
}
variable "repository_url" {
  type        = string
  description = "The URL of the ECR repository from the ECR module"
}