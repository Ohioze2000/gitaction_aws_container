output "repository_url" {
  value = aws_ecr_repository.app_repo.repository_url
}
# output "image_id" {
#   value = docker_registry_image.push_to_ecr.id
# }