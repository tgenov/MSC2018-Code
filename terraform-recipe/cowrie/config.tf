variable "region" {}
variable instance_type {}
variable "spot_price" {}
variable "instance_count" {}
variable ssh_public_key {}  
variable ssh_private_key {}
variable "cowrie_config" { type = "map" }


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
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_cloudwatch_metric_alarm" "autorecover" {
  alarm_name          = "ec2-autorecover"
  namespace           = "AWS/EC2"
  evaluation_periods  = "2"
  period              = "60"
  alarm_description   = "This metric auto recovers failed EC2 instances"
  alarm_actions       = ["arn:aws:automate:${var.region}:ec2:reboot"]
  statistic           = "Minimum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  metric_name         = "StatusCheckFailed"
  dimensions {
      InstanceId = "${element(aws_spot_instance_request.cowrie.*.spot_instance_id, count.index)}"
  }
}

resource "aws_key_pair" "generated_key" {
  key_name   = "honeypot_ssh_key"
  public_key = "${var.ssh_public_key}"
}

resource "aws_spot_instance_request" "cowrie" {
  count         = "${var.instance_count}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  subnet_id = "${aws_subnet.cowrie_subnet.id}"
  key_name = "${aws_key_pair.generated_key.key_name}"
  iam_instance_profile = "cowrie_instance_profile"
  spot_price = "${var.spot_price}"
  wait_for_fulfillment = true
  spot_type = "one-time"
  user_data = "${lookup(var.cowrie_config, count.index, "default")}"

  tags {
    Name = "cowrie${count.index}"
    Payload = "${lookup(var.cowrie_config, count.index, "default")}"
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
    private_key = "${var.ssh_private_key}"
  }

}

output "ip" {
  value = "${aws_spot_instance_request.cowrie.*.public_ip}"
}
