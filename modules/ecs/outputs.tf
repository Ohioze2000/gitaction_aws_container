output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.main.name
}

output "ecs_task_security_group_id" {
  value = aws_security_group.ecs_tasks_sg.id
}

output "sg_id" {
  value = aws_security_group.ecs_tasks_sg.id
}