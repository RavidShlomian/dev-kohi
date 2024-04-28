variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami" {
  description = "Ubuntu machine image to use for ec2 instance"
  type        = string
  default     = "ami-0914547665e6a707c" # Ubuntu 22.04 LTS // eu-north-1
}

variable "Project" {
  type    = string
  default = "Kohi"
}

variable "ENV" {
  type    = string
  default = "Dev"
}
variable "db_username" {
  type    = string
  default = "postgres"
}

variable "db_password" {
  type    = string
  default = "admin123"
}