#SNS Topic for CloudWatch Alarms ---
resource "aws_sns_topic" "cloudwatch_alarms_topic" {
  name = "${var.env_prefix}-cloudwatch-alarms"
  display_name = "${var.env_prefix} CloudWatch Alarms"

  tags = {
    Name = "${var.env_prefix}-cloudwatch-alarms"
  }
}
#CloudWatch Alarm for Average CPU Utilization across all web servers ----
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.env_prefix}-High-CPU-Utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ecs cpu utilization"
  
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  }

resource "aws_sns_topic" "alerts" {
  name = "${var.env_prefix}-ecs-alerts"

  tags = {
    Name = "${var.env_prefix}-High-CPU-Alarm"
  }
}

#Subscribe an email address to the SNS topic
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.cloudwatch_alarms_topic.arn
  protocol  = "email"
  endpoint  = "ohiozeberyl2000@gmail.com" # <--- IMPORTANT: Change this to your email address

  # You will receive a confirmation email. You must click the link in the email to confirm the subscription.
}
