variable "ami_id" {
  description = "AMI ID for the EC2 instance (Ubuntu 24.04 in us-east-1)"
  type        = string
  default     = "ami-091138d0f0d41ff90"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of the SSH key pair (must already exist in AWS)"
  type        = string
}

variable "key_path" {
  description = "Path to the private key file on your laptop (for SSH)"
  type        = string
}

variable "minecraft_image_tag" {
  description = "Docker image tag for the Minecraft server (stored in ECR)"
  type        = string
  default     = "latest" # update this to a pinned tag once CI/CD is working, to avoid accidentally deploying a broken image
}