output "diag_app_url" {
  value       = aws_lb.alb.dns_name
  description = "The public ALB DNS"
}

output "publisher_access_key" {
  value       = aws_iam_access_key.diag_ecr_key.id
  description = "AWS_ACCESS_KEY to publish to ECR"
}

output "publisher_secret_key" {
  value       = aws_iam_access_key.diag_ecr_key.secret
  description = "AWS_SECRET_ACCESS_KEY to upload to the ECR"
  sensitive   = true
}

output "ecr_url" {
  value       = aws_ecr_repository.repository.repository_url
  description = "The ECR repository URL"
}

output "ecr_repository_name" {
  value       = aws_ecr_repository.repository.name
  description = "The ECR repository name"
}

output "ecs_cluster" {
  value       = aws_ecs_cluster.cluster.name
  description = "The ECS cluster name"
}

output "ecs_service" {
  value       = aws_ecs_service.service.name
  description = "The ECS service name"
}

output "container_name" {
  value       = var.container.name
  description = "Container name for the ECS task"
}
