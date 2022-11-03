# -------------------------------
# key pair
# -------------------------------
resource "aws_key_pair" "keypair" {
  key_name   = "${var.project}-${var.environment}-keypair"
  public_key = file("./src/keys/testprj-dev-keypair.pub")
  tags = {
    Name    = "${var.project}-${var.environment}-keypair"
    Project = var.project
    Env     = var.environment
  }
}
# -------------------------------
# SSM Parameter Store
# -------------------------------
resource "aws_ssm_parameter" "host" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_HOST"
  type  = "String"
  value = aws_db_instance.mysql_standalone.address
}
resource "aws_ssm_parameter" "port" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_PORT"
  type  = "String"
  value = aws_db_instance.mysql_standalone.port
}
resource "aws_ssm_parameter" "database" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_DATABASE"
  type  = "String"
  value = "testprj"
}
resource "aws_ssm_parameter" "username" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_USERNAME"
  type  = "SecureString"
  value = aws_db_instance.mysql_standalone.username
}
resource "aws_ssm_parameter" "password" {
  name  = "/${var.project}/${var.environment}/app/MYSQL_PASSWORD"
  type  = "SecureString"
  value = aws_db_instance.mysql_standalone.password
}


# # -------------------------------
# # EC2 Instance
# # -------------------------------
# resource "aws_instance" "app_server" {
#   ami                         = data.aws_ami.app.id
#   instance_type               = "t2.micro"
#   subnet_id                   = aws_subnet.public_subnet_1a.id
#   associate_public_ip_address = true

#   iam_instance_profile = aws_iam_instance_profile.app_ec2_profile.name

#   vpc_security_group_ids = [
#     aws_security_group.app_sg.id,
#     aws_security_group.opmng_sg.id
#   ]
#   key_name = aws_key_pair.keypair.key_name

#   tags = {
#     Name    = "${var.project}-${var.environment}-app-ec2"
#     Project = var.project
#     Env     = var.environment
#     Type    = "app"
#   }
# }

# -------------------------------
# launch template
# -------------------------------
resource "aws_launch_template" "app_lt" {
  update_default_version = true

  name = "${var.project}-${var.environment}-app-lt"

  image_id = data.aws_ami.app.id

  key_name = aws_key_pair.keypair.key_name

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project}-${var.environment}-app-ec2"
      Project = var.project
      Env     = var.environment
      Type    = "app"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [
      aws_security_group.app_sg.id,
      aws_security_group.opmng_sg.id,
    ]
    delete_on_termination = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.app_ec2_profile.name
  }

  user_data = filebase64("./src/initialize.sh")
}

# -------------------------------
# auto scaling group
# -------------------------------
resource "aws_autoscaling_group" "app_asg" {
  name = "${var.project}-${var.environment}-app-asg"

  max_size         = 3
  min_size         = 1
  desired_capacity = 1

  health_check_grace_period = 300
  health_check_type         = "ELB"

  vpc_zone_identifier = [
    aws_subnet.public_subnet_1a.id,
    aws_subnet.public_subnet_1c.id,
  ]

  target_group_arns = [
    aws_lb_target_group.alb_target_group.arn,
  ]

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.app_lt.id
        version            = "$Latest"
      }

      override {
        instance_type = "t2.micro"
      }
    }
  }
}
resource "aws_autoscaling_policy" "app_asg_policy_out" {
  name                   = "${var.project}-${var.environment}-app-asg-policy-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}
resource "aws_autoscaling_policy" "app_asg_policy_in" {
  name                   = "${var.project}-${var.environment}-app-asg-policy-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}
resource "aws_cloudwatch_metric_alarm" "app_asg_alarm_high" {
  alarm_name          = "${var.project}-${var.environment}-app-asg-alarm-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.app_asg_policy_out.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
  treat_missing_data = "breaching"
}
resource "aws_cloudwatch_metric_alarm" "app_asg_alarm_low" {
  alarm_name          = "${var.project}-${var.environment}-app-asg-alarm-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.app_asg_policy_in.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
  treat_missing_data = "breaching"
}
