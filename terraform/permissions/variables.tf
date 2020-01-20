variable "project" {
  type        = string
  description = "The Google Cloud Platform project name"
}

variable "berglas_bucket" {
  description = "The bucket **that has already been boostrapped** by berglas"
  type        = string
}

variable "slug" {
  description = "A prefix slug for this instance (e.g prod, test)"
  type        = string
}

variable "database_url" {
  description = "The ODBC connection string"
  type        = string
}
