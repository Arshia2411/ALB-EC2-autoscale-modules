terraform {
    source  =   "./"
}
inputs   =   {
    vpc_cidr_block = "10.0.0.0/16"
    region = "us-east-1"
    avail_zone1 = "us-east-1a"
    avail_zone2 = "us-east-1b"
    pubRT_cidr_block = "0.0.0.0/0"
    privRT_cidr_block = "0.0.0.0/0"
    pubSub1_cidr_block = "10.0.0.0/24"
    privSub_cidr_block = "10.0.1.0/24"
    instance_type = "t2.micro"
    ami_id = "ami-033b95fb8079dc481"
}
