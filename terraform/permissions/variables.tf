variable "project" {
  type        = string
  description = "Google Cloud Platform project name"
}

variable "berglas_bucket" {
  type        = string
  description = "The bucket **that has already been boostrapped** by berglas"
}

variable "slug" {
  type        = string
  description = "A prefix slug for this instance (e.g prod, test)"
}

variable "database_url" {
  type        = string
  description = "The ODBC connection string"
}
