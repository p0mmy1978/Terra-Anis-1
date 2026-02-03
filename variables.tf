variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
  default     = "ContosoResourceGroup"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    project = "multi-region-vnets"
    owner   = "terraform"
  }
}
