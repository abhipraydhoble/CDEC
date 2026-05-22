########################################
# VARIABLES
########################################
variable "ami_id" {
  default = "ami-0f5ee92e2d63afc18" # change
}

variable "instance_type" {
  default = "t3.micro"
}

########################################
# SECURITY GROUP
########################################
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = "vpc-0b513c39beed873c2" # change

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

########################################
# LAUNCH TEMPLATE
########################################
resource "aws_launch_template" "web_lt" {
  name = "web-launch-template"

  image_id      = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd

    mkdir -p /var/www/html/mobile
    mkdir -p /var/www/html/laptop

    echo "<h1>HOME PAGE</h1><p>Use /mobile or /laptop</p>" > /var/www/html/index.html

    echo "<h1>MOBILE PAGE</h1>" > /var/www/html/mobile/index.html
    echo "<h1>LAPTOP PAGE</h1>" > /var/www/html/laptop/index.html

    chown -R apache:apache /var/www/html
    systemctl restart httpd
  EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

########################################
# TARGET GROUPS
########################################
resource "aws_lb_target_group" "tg_home" {
  name     = "tg-home"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0b513c39beed873c2"

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group" "tg_laptop" {
  name     = "tg-laptop"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0b513c39beed873c2"

  health_check {
    path = "/laptop/"
  }
}

resource "aws_lb_target_group" "tg_mobile" {
  name     = "tg-mobile"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0b513c39beed873c2"

  health_check {
    path = "/mobile/"
  }
}

########################################
# AUTO SCALING GROUP
########################################
resource "aws_autoscaling_group" "web_asg" {
  desired_capacity = 2
  min_size         = 1
  max_size         = 3

  vpc_zone_identifier = [
    "subnet-05bda144578ea9914", # change
    "subnet-0b6e1ae4003ff61b3"
  ]

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  target_group_arns = [
    aws_lb_target_group.tg_home.arn,
    aws_lb_target_group.tg_laptop.arn,
    aws_lb_target_group.tg_mobile.arn
  ]

  tag {
    key                 = "Name"
    value               = "web-asg"
    propagate_at_launch = true
  }
}

########################################
# APPLICATION LOAD BALANCER
########################################
resource "aws_lb" "alb" {
  name               = "web-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.web_sg.id]

  subnets = [
    "subnet-05bda144578ea9914", # change
    "subnet-0b6e1ae4003ff61b3"
  ]
}

########################################
# LISTENER
########################################
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_home.arn
  }
}

########################################
# LISTENER RULES
########################################
resource "aws_lb_listener_rule" "laptop_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_laptop.arn
  }

  condition {
    path_pattern {
      values = ["/laptop/*"]
    }
  }
}

resource "aws_lb_listener_rule" "mobile_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_mobile.arn
  }

  condition {
    path_pattern {
      values = ["/mobile/*"]
    }
  }
}
