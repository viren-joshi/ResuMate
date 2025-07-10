variable "subnet_ids" {
    type = list(string)
    description = "List of subnet IDs"
}

variable "db_security_group_id" {
    type = string
    description = "DB Security Group ID"
}