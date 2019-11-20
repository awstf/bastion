variable "name" {
  type        = string
  description = "Bastion host name."
}

variable "min" {
  default     = 1
  description = "Minimum number of bastion instances."
}

variable "max" {
  default     = 1
  description = "Maximum number of bastion instances."
}

variable "desired" {
  default     = 1
  description = "Desired number of bastion instances."
}

variable "vpc_id" {
  description = "ID of a VPC where to create bastion host."
}

variable "subnets" {
  description = "Public Subnets where to create bastion host."
}

variable "whitelist" {
  default     = ["0.0.0./0"]
  description = "SSH whitelisted IPv4 subnets."
}

variable "instance_types_ondemand" {
  default     = "t3.nano"
  description = "instance_types_ondemand parameter for Spotinst Elastigroup."
}

variable "instance_types_spot" {
  default     = ["t3.nano", "t3a.nano", "t3.micro", "t3a.micro", "t2.micro"]
  description = "instance_types_spot parameter for Spotinst Elastigroup."
}

variable "instance_types_preferred_spot" {
  default     = ["t3.nano", "t3a.nano"]
  description = "instance_types_preferred_spot parameter for Spotinst Elastigroup."
}
