output "ecs_task_execution_role_arn" {
    value = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_cluster" {
    value = aws_ecs_cluster.ecs_cluster.name
}

output "aecs_service" {
    value = aws_ecs_service.ecs_service.name
}