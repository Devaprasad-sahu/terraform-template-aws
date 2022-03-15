variable "user_arn" {
type = string
default = " "
}

/* provide the arn of an IAM user as default value
to provide the arn of root user follow the below mentioned pattern
arn:aws:iam::<AWS Account ID>:root
for example if you AWS Account ID is 725892552063 then the default value will be "arn:aws:iam::725892552063:root"
*/