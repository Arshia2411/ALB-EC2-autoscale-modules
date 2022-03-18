variable "vpc_cidr_block" {
  type = string
  default = null
}
variable "region" {
  type    = string
    default = null

}
variable "avail_zone1"{
    type    =   string
      default = null

}
variable "avail_zone2"{
    type    =   string
      default = null

}
variable "pubRT_cidr_block" {
  type = string
    default = null

}
variable "privRT_cidr_block" {
  type = string
    default = null

}
variable "pubSub1_cidr_block" {
  type = string
    default = null

}
variable "privSub_cidr_block" {
  type = string
    default = null

}
variable "instance_type" {
  type = string
    default = null

}
variable "ami_id" {
  type = string
    default = null

}
