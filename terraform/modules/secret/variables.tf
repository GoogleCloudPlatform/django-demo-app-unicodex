variable project {
  type        = string
  description = "The Google Cloud Platform project name"
}

variable name {
  type        = string
  description = "Secret name"
}

variable secret_data {
  description = "Secret data"
  type        = string
}

variable accessors {
  description = "List of accessors for secret (service accounts, etc)"
  type        = list(string)
}