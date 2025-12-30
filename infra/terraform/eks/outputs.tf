output "k3s_node_public_ip" {
  value = aws_instance.k3s_node.public_ip
}

output "k3s_node_public_dns" {
  value = aws_instance.k3s_node.public_dns
}

output "ssh_command" {
  value = "ssh ubuntu@${aws_instance.k3s_node.public_ip}" # Requires key pair if assigned, using SSM is better
}
