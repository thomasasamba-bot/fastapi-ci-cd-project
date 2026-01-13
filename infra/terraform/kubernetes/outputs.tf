output "cluster_node_public_ip" {
  value = aws_instance.cluster_node.public_ip
}

output "cluster_node_public_dns" {
  value = aws_instance.cluster_node.public_dns
}

output "ssh_command" {
  value = "ssh ubuntu@${aws_instance.cluster_node.public_ip}" # Requires key pair if assigned, using SSM is better
}
