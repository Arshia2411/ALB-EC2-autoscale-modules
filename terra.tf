provider "aws" {
    region = var.region
}

#calling VPC module
module "create_VPC" {
    source = "./vpc"

    vpc_cidr_block = var.vpc_cidr_block

}

module "create_subnets" { 
    source = "./subnets"

    vpc_id = module.create_VPC.test_vpc_id
    avail_zone1 = var.avail_zone1
    avail_zone2 = var.avail_zone2
    pubRT_cidr_block = var.pubRT_cidr_block
    privRT_cidr_block = var.privRT_cidr_block
    pubSub1_cidr_block = var.pubSub1_cidr_block
    privSub_cidr_block = var.privSub_cidr_block
}

#create an Application Load Balancer.
#attach the previous availability zones' subnets into this load balancer.
resource "aws_lb" "alb_1" {
    #name = "my-alb"
    internal = true # set lb for public access
    load_balancer_type = "application" # use Application Load Balancer
    security_groups = [aws_security_group.alb_security_group.id]
    subnets = [ # attach the availability zones' subnets.
        module.create_subnets.pubSub1_id,
        module.create_subnets.privSub1_id 
    ]
}
# prepare a security group for our load balancer alb_1.
resource "aws_security_group" "alb_security_group" {
    vpc_id = module.create_VPC.test_vpc_id
    ingress = [
    {
      # ssh port allowed from any ip
      description      = "ssh"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      # http port allowed from any ip
      description      = "http"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ]
  egress = [
    {
      description      = "all-open"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ]
}
resource "aws_lb_listener" "alb_1_listener" {  
    load_balancer_arn = aws_lb.alb_1.arn
    port = 80  
    protocol = "HTTP"
    default_action {    
        target_group_arn = aws_lb_target_group.alb_1_target_group.arn
        type = "forward"
    }
}

# alb_1 will forward the request to a particular app,
# that listen on 8080 within instances on test_vpc.
resource "aws_lb_target_group" "alb_1_target_group" {
    port = 80
    protocol = "HTTP"
    vpc_id = module.create_VPC.test_vpc_id
}
resource "aws_launch_configuration" "my_launch_configuration" {

    # Amazon Linux 2 AMI (HVM), SSD Volume Type (ami-0f02b24005e4aec36).
    image_id = var.ami_id
    key_name = "test"

    instance_type = var.instance_type
    security_groups = [aws_security_group.launch_config_security_group.id]
    associate_public_ip_address = true
    lifecycle {
        # ensure the new instance is only created before the other one is destroyed.
        create_before_destroy = true
    }

    # execute bash scripts inside deployment.sh on instance's bootstrap.
    # what the bash scripts going to do in summary:
    # fetch a hello world app from Github repo, then deploy it in the instance.
    user_data = file("website.sh")
}
# security group for launch config my_launch_configuration.
resource "aws_security_group" "launch_config_security_group" {
    vpc_id = module.create_VPC.test_vpc_id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
#create an autoscaling then attach it into alb_1_target_group.
resource "aws_autoscaling_attachment" "my_aws_autoscaling_attachment" {
    alb_target_group_arn = aws_lb_target_group.alb_1_target_group.arn
    autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.id
}
#define the autoscaling group.
# attach my_launch_configuration into this newly created autoscaling group below.
resource "aws_autoscaling_group" "my_autoscaling_group" {
    name = "my-autoscaling-group"
    desired_capacity = 3 # ideal number of instance alive
    min_size = 3 # min number of instance alive
    max_size = 7 # max number of instance alive
    health_check_type = "EC2"

    # allows deleting the autoscaling group without waiting
    # for all instances in the pool to terminate
    force_delete = true

    launch_configuration = aws_launch_configuration.my_launch_configuration.id
    vpc_zone_identifier = [
        module.create_subnets.pubSub1_id,
        module.create_subnets.privSub1_id 
    ]
    timeouts {
        delete = "15m" # timeout duration for instances
    }
    lifecycle {
        # ensure the new instance is only created before the other one is destroyed.
        create_before_destroy = true
    }
}