output "ec2-web_server_public_ip" {
  description = "The public IP address assigned to the main web server instance."

  value = aws_instance.ec2-web_server.public_ip
}
