data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1a"]
  }


}

data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}



resource "aws_security_group" "web_app_sg" {
  vpc_id      = data.aws_vpc.default.id
  description = "Allow web and SSH traffic"
  name        = "web-app-security-group"

  tags = {
    Name = "web-app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.web_app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.web_app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_k3s_API" {
  security_group_id = aws_security_group.web_app_sg.id
  cidr_ipv4         = var.my_ip
  from_port         = 6443
  ip_protocol       = "tcp"
  to_port           = 6443
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.web_app_sg.id
  cidr_ipv4         = var.my_ip
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.web_app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = data.aws_route53_zone.selected.name
  type    = "A"
  ttl     = "300"
  records = [aws_instance.ec2-web_server.public_ip]

  allow_overwrite = true
}

resource "aws_route53_record" "www" {
  zone_id         = data.aws_route53_zone.selected.zone_id
  name            = "www.${data.aws_route53_zone.selected.name}"
  type            = "CNAME"
  ttl             = "300"
  records         = [data.aws_route53_zone.selected.name]
  allow_overwrite = true
}

resource "aws_instance" "ec2-web_server" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.web_app_sg.id]
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnets.default_subnets.ids[0]

  user_data                   = file("../scripts/setup_host.sh")
  user_data_replace_on_change = true

  tags = {
    Name = "web-app-host"
  }
}

