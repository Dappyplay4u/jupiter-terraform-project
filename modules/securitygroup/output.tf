output "alb_security_group_id" {
    value = aws_security_group.alb_security_group.id
}

output "webserver_security_group_id" {
    value = aws_security_group.webserver_security_group.id
}

output "ssh_security_group_id" {
    value = aws_security_group.ssh_security_group.id
}

output "ecs_security_group_id" {
    value = aws_security_group.ecs_security_group.id
}

output "database_security_group_id" {
    value = aws_security_group.database_security_group.id
}


