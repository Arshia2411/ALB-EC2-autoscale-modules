#creating VPC
resource "aws_vpc" "test_vpc" {
    cidr_block = var.vpc_cidr_block
    #enable_dns_hostnames = true
}