output "cloudwatch_alarms_topic_arn" {
  value = aws_sns_topic.alerts.arn
}
