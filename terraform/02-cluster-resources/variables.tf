variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type        = string
  default     = "claude-debug-demo"
  description = "Must match the cluster_name set in 01-cluster."
}
