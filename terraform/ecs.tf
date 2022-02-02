### Create Fargate ECS
resource "aws_ecs_cluster" "cluster" {
  name               = var.ecs.cluster_name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = "100"
  }
}



### Tasks definition and corresponding ECS service
resource "aws_ecs_task_definition" "task" {
  family = "service"
  requires_compatibilities = [
    "FARGATE",
  ]
  execution_role_arn = aws_iam_role.diag_fargate_role.arn
  network_mode       = "awsvpc"
  cpu                = 256
  memory             = 512
  container_definitions = <<DEFINITION
    [
      {
        "name": "${var.container.name}",
        "image": "${var.container.image}",
        "essential": true,
        "portMappings": [
          {
            "containerPort": 8000,
            "hostPort": 8000
          }
        ],
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "diag-app-logs",
            "awslogs-region": "us-west-2",
            "awslogs-stream-prefix": "diag-app-logs",
            "awslogs-create-group": "true"
          }
        }
      }
    ]
    DEFINITION
}

### ECS service
resource "aws_ecs_service" "service" {
  name            = var.ecs.service_name
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 2

  network_configuration {
    subnets          = [for s in data.aws_subnet.subnets : s.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb-diag-tg.arn  # our target group
    container_name   = var.container.name
    container_port   = 8000
  }
  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 100
  }
}
