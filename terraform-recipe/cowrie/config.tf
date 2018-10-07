variable "region" {}
variable "spot_price" {}
variable "instance_count" {}

provider "aws" {
  region = "${var.region}"
  profile = "subnet"
}

resource "aws_vpc" "cowrie" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "cowrie"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.cowrie.id}"

  ingress {
    protocol  = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    label = "cowrie"
  }
}

resource "aws_default_network_acl" "default" {

  default_network_acl_id = "${aws_vpc.cowrie.default_network_acl_id}"

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags {
    label = "cowrie"
  }
}

resource "aws_subnet" "cowrie_subnet" {
  vpc_id                  = "${aws_vpc.cowrie.id}"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  tags {
    Name = "cowrie"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.cowrie.id}"
  tags {
    Name = "cowrie"
  }
}

resource "aws_route_table" "public_routetable" {
  vpc_id = "${aws_vpc.cowrie.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }

  tags {
    label = "cowrie"
  }
}

resource "aws_route_table_association" "cowrie_subnet" {
  subnet_id      = "${aws_subnet.cowrie_subnet.id}"
  route_table_id = "${aws_route_table.public_routetable.id}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-artful-17.10-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "terraform-ssh" {
  key_name = "terraform-ssh"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDlyMC7K+Z4QTm+QZD4uDDSAlLNVCdx82Glp7nVWQuRCGN/xAOB93oeozKf++dYdaM7W/8Mkd3FNf/2ggufXzSDkdLR43BG1PomT1tu4Yr7ohBrR7W5MSWvaXtibsya3OLbz3aAqbztdWlhtnhClLAkbWeHvBZsedVlQ8ZqHV/WhHW1ZXMTjSxg1YeVSLgImPsd5VIC9uBW9NnPgkLYJ9j3M7TPM4Uf5ksInprVtmHB76o8ISbh4GiJ5YpAyNrd+vEu+ZbAt7RhwaAZphewbosYitJTYNivPAL7HwJEAOVKXbxlqgWQRC5QmVyKlDTQwOPvFHzUR6PEzUhGRg8R/t23 todor@tesla.lan.subnet.co.za"
}

resource "aws_cloudwatch_metric_alarm" "autorecover" {
  alarm_name          = "ec2-autorecover"
  namespace           = "AWS/EC2"
  evaluation_periods  = "2"
  period              = "60"
  alarm_description   = "This metric auto recovers EC2 instances"
  alarm_actions       = ["arn:aws:automate:${var.region}:ec2:reboot"]
  statistic           = "Minimum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  metric_name         = "StatusCheckFailed"
  dimensions {
      InstanceId = "${element(aws_spot_instance_request.cowrie.*.spot_instance_id, count.index)}"
  }
}

resource "aws_spot_instance_request" "cowrie" {
  count         = "${var.instance_count}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.cowrie_subnet.id}"
  key_name = "terraform-ssh"
  iam_instance_profile = "cowrie_instance_profile"
  spot_price = "${var.spot_price}"
  wait_for_fulfillment = true
  spot_type = "one-time"

  tags {
    Name = "cowrie"
  }

  provisioner "file" {
    source      = "payload"
    destination = "/home/ubuntu/scripts/"
  }

  provisioner "remote-exec" {
  inline = [
      "chmod +x scripts/prepare.sh",
      "scripts/prepare.sh > /tmp/prepare.log"
    ]
  }

  connection {
    type     = "ssh"
    user     = "ubuntu"
    agent_identity = "/Users/todor/.ssh/terraform-ssh"
  }

}

output "ip" {
  value = "${aws_spot_instance_request.cowrie.*.public_ip}"
}
