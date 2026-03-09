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

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.env_prefix}-ECS-Performance"

  dashboard_body = jsonencode({
    widgets = [
      # Widget 1: CPU Utilization
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/ECS", "CPUUtilization", "ServiceName", "${var.ecs_service_name}", "ClusterName", "${var.ecs_cluster_name}" ]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "${var.env_prefix}: ECS CPU Utilization (%)"
          view   = "timeSeries"
          stacked = false
        }
      },
      # Widget 2: Memory Utilization
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/ECS", "MemoryUtilization", "ServiceName", "${var.ecs_service_name}", "ClusterName", "${var.ecs_cluster_name}" ]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "${var.env_prefix}: ECS Memory Utilization (%)"
          view   = "timeSeries"
          stacked = false
        }
      }
    ]
  })
}
