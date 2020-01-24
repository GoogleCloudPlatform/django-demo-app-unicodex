variable "project" {
  type        = string
  description = "Google Cloud Platform project name"
}

variable "region" {
  type    = string
  description  = "Google Cloud Platform region name"
  default = "us-central1"
}

variable "instance_name" {
  type        = string
  description = "Name of the postgres instance to use (for your project and region)"
}

variable "slug" {
  type        = string
  description = "A prefix slug for this instance (e.g prod, test)"
}

