output "minecraft_node_public_ip" {
  description = "Public IP of the Minecraft node: SSH here from your laptop"
  value       = aws_instance.minecraft.public_ip
}

output "ecr_repository_url" {
  description = "ECR repository URL: use this in the GitHub Actions workflow"
  value       = aws_ecr_repository.minecraft-storage.repository_url
}

output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = aws_vpc.cs312.id
}