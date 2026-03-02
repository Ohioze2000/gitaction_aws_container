# 1. The Execution Role (The "AWS side" role)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.env_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Attach the standard Amazon policy for ECR and Logging
resource "aws_iam_role_policy_attachment" "ecs_execution_standard" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2. The Task Role (The "My App" role)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.env_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Example: Allow the app to read from S3 (optional)
resource "aws_iam_role_policy" "app_permissions" {
  name = "${var.env_prefix}-app-permissions"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_execution_logs_creation" {
  name = "${var.env_prefix}-ecs-logs-creation"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["logs:CreateLogGroup"]
        Effect   = "Allow"
        Resource = ["arn:aws:logs:us-east-1:*:log-group:/ecs/${var.env_prefix}-app*"]
      }
    ]
  })
}