/* It has to be noted that the default value for the variable sns_topic is the "arn" of the sns topic 
but not the name of the topic
*/
variable "sns_topic" {
default = ""
}

variable "instance_id" {
type = string
default = ""
}
