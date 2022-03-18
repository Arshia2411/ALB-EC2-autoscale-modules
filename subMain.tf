# setup internet gateway for public subnets.
resource "aws_internet_gateway" "test_vpc_igw" {
    vpc_id = var.vpc_id
}

# creating a pubblic RT
resource "aws_route_table" "public_rt" {
    vpc_id = var.vpc_id
    route {
        cidr_block = var.pubRT_cidr_block
        gateway_id = aws_internet_gateway.test_vpc_igw.id
    }
}
#creating a public subnet
#subnet in availaility zone 1
resource "aws_subnet" "public_subnet_1a" {
    vpc_id = var.vpc_id
    cidr_block = var.pubSub1_cidr_block
    availability_zone = var.avail_zone1
    map_public_ip_on_launch = "true"

}
# associate the internet gateway
resource "aws_route_table_association" "pubSub_1a_rt" {
    subnet_id = aws_subnet.public_subnet_1a.id
    route_table_id = aws_route_table.public_rt.id
}

# creating a private subnet
resource "aws_subnet" "private_subnet_1c" {
    vpc_id = var.vpc_id
    cidr_block = var.privSub_cidr_block
    availability_zone = var.avail_zone2
    map_public_ip_on_launch = false              
}

# elastic IP for NAT
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.test_vpc_igw]
}   

# creating NAT
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1a.id  
}

#creating RT fpr private subnet
resource "aws_route_table" "private-rt" {
    vpc_id = var.vpc_id
  
    route {
      cidr_block = var.privRT_cidr_block
      gateway_id = aws_nat_gateway.nat.id
    }
}   
resource "aws_route_table_association" "private-rt" {
    subnet_id      = aws_subnet.private_subnet_1c.id
    route_table_id = aws_route_table.private-rt.id
}