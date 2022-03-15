variable "vpc_cidr" {
 description = "the CIDR for VPC"
 type = string
 default = "10.0.0.0/16"
}

variable "public_cidrs" {
  type = list
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_cidrs" {
  type = list
  default = ["10.0.3.0/24", "10.0.4.0/25"]

}
