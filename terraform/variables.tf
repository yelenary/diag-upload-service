variable "vpc_id" {
  default = "vpc-0df9ad5d58bca84ff"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"]
}

variable "deregistration_delay" {
  default     = "300"
  description = "The default deregistration delay"
}

variable "health_check_path" {
  default     = "/"
  description = "The default health check path"
}

variable "allow_cidr_block" {
  default     = ["0.0.0.0/0"]
  description = "Specify cidr block that is allowed to access the LoadBalancer"
}

variable "environment" {
  default = "diag-environment"
}

variable "ecr_repo"{
  default = "cribl-registry"
  description = "Specify repository name on ECR"
}

variable "alb" {
  type = object({
     alb_name    = string
     internal    = string
  })
  default = {
     alb_name    = "diag-alb"
     internal    = "false"
     }
}

variable "ecs" {
  type = object({
    cluster_name = string
    service_name = string
  })
  default = {
    cluster_name = "diag-ecs"
    service_name = "diag-service"
  }
  description = "ECS configuration"
}

variable "container" {
  type  = object({
    name  = string
    image = string
    ports = list(string)
  })
  default = {
    name  = "diag-app"
    image = "goat/diag"
    ports = [8000]
  }
  description = "Container configuration to deploy"
}
