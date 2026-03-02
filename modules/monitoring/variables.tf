variable "env_prefix"{
  type = string
  description = "ENVIRONMENT PREFIX"
}

variable "ecs_cluster_name" {
  type        = string
  description = "The name of the ECS cluster to monitor"
}

variable "ecs_service_name" {
  type        = string
  description = "The name of the ECS service to monitor"
}