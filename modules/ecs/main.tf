# generates an iam policy document in json format for the ecs task execution role
data "aws_iam_policy_document" "ecs_tasks_execution_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# create an iam role
resource "aws_iam_role" "ecs_tasks_execution_role" {
  name                = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy  = data.aws_iam_policy_document.ecs_tasks_execution_role_policy.json
}

# attach ecs task execution policy to the iam role
resource "aws_iam_role_policy_attachment" "ecs_tasks_execution_role" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# create ecs cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name      = "${var.project_name}-cluster"

  setting {
    name    = "containerInsights"
    value   = "disabled"
  }
}

# create cloudwatch log group
resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/${var.project_name}-task-definition"

  lifecycle {
    create_before_destroy = true
  }
}

# create task definition
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                    = "${var.project_name}-task-definition"
  execution_role_arn        = var.ecs_task_execution_role_arn
  network_mode              = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  cpu                       = 2048
  memory                    = 4096

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions     = jsonencode([
    {
      name                  = "${var.project_name}-container"
      image                 = var.container_image
      essential             = true

      portMappings          = [
        {
          containerPort     = 80
          hostPort          = 80
        }
      ]
      
      ulimits = [
        {
          name = "nofile",
          softLimit = 1024000,
          hardLimit = 1024000
        }
      ]

      logConfiguration = {
        logDriver   = "awslogs",
        options     = {
          "awslogs-group"          = aws_cloudwatch_log_group.log_group.name,
           "awslogs-region"        = var.region
          "awslogs-stream-prefix"  = "ecs"
        }
      }
    }
  ])
}

# create ecs service
resource "aws_ecs_service" "ecs_service" {
  name              = "${var.project_name}-service"
  launch_type       = "fargate"
  cluster           = aws_ecs_cluster.ecs_cluster.id
  task_definition   = aws_ecs_task_definition.ecs_task_definition.arn
  platform_version  = "latest"
  desired_count     = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # task tagging configuration
  enable_ecs_managed_tags            = false
  propagate_tags                     = "SERVICE"

  # vpc and security groups
  network_configuration {
    subnets                 = [var.private_app_subnet_az1_id, private_app_subnet_az2_id]
    security_groups         = [var.ecs_security_group_id] 
    assign_public_ip        = false
  }

  # load balancing
  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "${var.project_name}-container"
    container_port   = 80
  }
}