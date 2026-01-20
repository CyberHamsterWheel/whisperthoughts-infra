variable "domain_name" {
  default = "whisperthoughts.com"
}

variable "key_name" {
  default = "web-app"
}

variable "instance_type" {
  default = "t3.small"
}

variable "my_ip" {
  description = "The CIDR block for my local machine SSH access"
  type        = string
}


