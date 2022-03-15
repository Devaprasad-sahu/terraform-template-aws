provider "aws" {
  region = "us-west-2"
}

data "aws_availability_zones" "available" {}

data "aws_ami" "centos" {
  /* owners      = ["679593333241"]  ### this owner is a premium subscription provider*/
  owners      = ["410186602215"]       /* replaced the owner with free tier provider */
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

/*
#######  To find owners #######
Go to https://us-west-2.console.aws.amazon.com/ec2 
--> images --> AMIs --> public images --> Search for CentOS Linux 7 x86_64 HVM EBS
you will find AMIs select an owner 
*/


resource "aws_key_pair" "mytest-key" {
  key_name   = "my-test-terraform-key-new1"
  public_key = "${file(var.my_public_key)}"
}

/* generate an ssh key using ssh-keygen in a particular directory 
in this example i have created an ssh key in /tmp of local server
*/

data "template_file" "init" {
  template = "${file("${path.module}/userdata.tpl")}"
}

resource "aws_instance" "my-test-instance" {
  count                  = 2
  ami                    = "${data.aws_ami.centos.id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${aws_key_pair.mytest-key.id}"
  vpc_security_group_ids = ["${var.security_group}"]
  subnet_id              = "${element(var.subnets, count.index )}"
  user_data              = "${data.template_file.init.rendered}"

  tags = {
    Name = "my-instance-${count.index + 1}"
  }
}

resource "aws_ebs_volume" "my-test-ebs" {
  count             = 2
 /* availability_zone = "${data.aws_availability_zones.available.names[count.index]}" */
  availability_zone = "${element(var.zones, count.index)}"
  size              = 1
  type              = "gp2"
}
/* asper the above template we are creating 2 instances in 2 separate subnets, because the subnet ids are provided as input variables
this creates 2 instances in the the two different availability zones in which our subnets are present
#######The volume and instance must be in the same Availability Zone######
so creating ebs volumes in the same availability zones can overcome the error : "The volume  is not in the same availability zone as instance"
*/

resource "aws_volume_attachment" "my-vol-attach" {
  count        = 2
  device_name  = "/dev/xvdh"
  instance_id  = "${aws_instance.my-test-instance.*.id[count.index]}"
  volume_id    = "${aws_ebs_volume.my-test-ebs.*.id[count.index]}"
  force_detach = true
}