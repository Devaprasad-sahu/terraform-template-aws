variable "my_public_key" {
default = "/tmp/id_rsa.pub"
}
/* generate an ssh key using ssh-keygen in a particular directory 
in this example i have created an ssh key in /tmp of local server
*/

variable "instance_type" {
default = ""
}

/* instance type can be t2.micro or any other depending on requirement*/

variable "security_group" {
default = ""
}


variable "subnets" {
  type = list
 default = [" ", " "]
}

variable "zones" {
 type = list
 default = ["", ""]
}
/* provide availability zones exactly same in which the subnets are present
example ["us-west-2a", "us-west-2b"]  ## if your subnet1 belongs to us-west-2a and subnet2 belongs to us-west-2b ##
*/
