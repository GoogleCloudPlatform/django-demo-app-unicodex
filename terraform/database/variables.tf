variable "project" {
  type        = string
  description = "The Google Cloud Platform project name"
}

variable "region" {
  default = "us-central1"
  type    = string
}

variable "instance_name" {
  description = "Name of the postgres instance to use (for your project and region)"
  type        = string
}

variable "slug" {
  description = "A prefix slug for this instance (e.g prod, test)"
  type        = string
}

