variable "vpc_id" {
default = ""
}

variable "hostname" {
  type = list
 default = [""]           
}

/* provide a suitable string for example if we provide default value as "test", 
 the output will be "test.example.com" */

variable "arecord" {
  type = list
 default = [""]
}

/* for arecord default value provide the "Elasticip", for test purpose you can use public ip of you Ec2 instance*/ 