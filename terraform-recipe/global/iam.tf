/* Global policies and IAM roles */

variable "region" {}

provider "aws" {
  region = "${var.region}"
  profile = "subnet"
}

resource "aws_iam_role" "cowrie_s3_writer" {
  name = "cowrie_s3_writer"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cowrie_s3_writer_policy" {
  name = "cowrie_s3_writer_policy"
  role = "${aws_iam_role.cowrie_s3_writer.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": [
            "arn:aws:s3:::cowrie-json-logs",
            "arn:aws:s3:::cowrie-malware-samples",
            "arn:aws:s3:::cowrie-tty-data"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": [
          "arn:aws:s3:::cowrie-json-logs/*",
          "arn:aws:s3:::cowrie-malware-samples/*",
          "arn:aws:s3:::cowrie-tty-data/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "cowrie_instance_profile" {
    name = "cowrie_instance_profile"
    role = "cowrie_s3_writer"
}

output "cowrie_instance_profile" {
  value = "${aws_iam_instance_profile.cowrie_instance_profile.name}"
}
