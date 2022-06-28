variable "departments" {
  description = "List of departments.  Used to create the corresponding S3 Buckets (one per department)."
  type        = list(string)
  default     = ["Finance", "Administration"]
}