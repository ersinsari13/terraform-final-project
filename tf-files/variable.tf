variable "port-number" {
    default = [80,443]
}
variable "instance_type" {
  default = "t2.micro"
}
variable "key_name" {
}
variable "git-token" {
}
variable "domain_name" {                                #enter your damain name
}
variable "max_size" {
    default = 3
}
variable "min_size" {
  default = 1
}
variable "desired_capacity" {
    default = 2
}
variable "instance_class" {
    default = "db.t3.micro"
}