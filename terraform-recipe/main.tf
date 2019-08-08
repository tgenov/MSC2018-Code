variable "instance_count" {
  description = "Number of instances to launch"
  default = 3
}

variable "instance_type" {
  description = "The type of EC2 instance to launch."
  default = "t3.nano"
}

variable "cowrie_config" {
  type = "map"

  # Launch each instance with a different payload
  # References a path under the "./payload" directory
  default = {
    "0" = "arm-default"
    "1" = "arm-elf-patch"
    "2" = "arm-responder"
  }
}

module "cowrie-global" {
  source = "global"
  region = "us-east-1"
}

module "pricing" {
  source = "pricing"
}

module "cowrie-us-east-1" {
  source = "cowrie"
  region = "us-east-1"
  cowrie_config = "${var.cowrie_config}"
  spot_price = "${module.pricing.spot["us-east-1"]}"
  instance_count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ssh_public_key = "${module.cowrie-global.public_key}"
  ssh_private_key = "${module.cowrie-global.private_key}"
}

module "cowrie-us-east-2" {
  source = "cowrie"
  region = "us-east-2"
  cowrie_config = "${var.cowrie_config}"
  spot_price = "${module.pricing.spot["us-east-2"]}"
  instance_count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  instance_type = "${var.instance_type}"
  ssh_public_key = "${module.cowrie-global.public_key}"
  ssh_private_key = "${module.cowrie-global.private_key}"
}

module "cowrie-us-west-1" {
  source = "cowrie"
  region = "us-west-1"
  cowrie_config = "${var.cowrie_config}"
  spot_price = "${module.pricing.spot["us-west-1"]}"
  instance_count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ssh_public_key = "${module.cowrie-global.public_key}"
  ssh_private_key = "${module.cowrie-global.private_key}"
}

module "cowrie-us-west-2" {
  source = "cowrie"
  region = "us-west-2"
  cowrie_config = "${var.cowrie_config}"
  spot_price = "${module.pricing.spot["us-west-2"]}"
  instance_count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ssh_public_key = "${module.cowrie-global.public_key}"
  ssh_private_key = "${module.cowrie-global.private_key}"
}

module "cowrie-ca-central-1" {
  source = "cowrie"
  region = "ca-central-1"
  cowrie_config = "${var.cowrie_config}"
  spot_price = "${module.pricing.spot["ca-central-1"]}"
  instance_count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ssh_public_key = "${module.cowrie-global.public_key}"
  ssh_private_key = "${module.cowrie-global.private_key}"
}

module "cowrie-eu-west-1" {
  source = "cowrie"
  region = "eu-west-1"
  cowrie_config = "${var.cowrie_config}"
  spot_price = "${module.pricing.spot["eu-west-1"]}"
  instance_count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ssh_public_key = "${module.cowrie-global.public_key}"
  ssh_private_key = "${module.cowrie-global.private_key}"
}

module "cowrie-eu-west-2" {
  source = "cowrie"
  region = "eu-west-2"
  cowrie_config = "${var.cowrie_config}"
  spot_price = "${module.pricing.spot["eu-west-2"]}"
  instance_count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ssh_public_key = "${module.cowrie-global.public_key}"
  ssh_private_key = "${module.cowrie-global.private_key}"
}

module "cowrie-eu-central-1" {
  source = "cowrie"
  region = "eu-central-1"
  cowrie_config = "${var.cowrie_config}"
  spot_price = "${module.pricing.spot["eu-central-1"]}"
  instance_count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ssh_public_key = "${module.cowrie-global.public_key}"
  ssh_private_key = "${module.cowrie-global.private_key}"
}

module "cowrie-ap-northeast-1" {
  source = "cowrie"
  region = "ap-northeast-1"
  cowrie_config = "${var.cowrie_config}"
  spot_price = "${module.pricing.spot["ap-northeast-1"]}"
  instance_count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ssh_public_key = "${module.cowrie-global.public_key}"
  ssh_private_key = "${module.cowrie-global.private_key}"
}

module "cowrie-ap-northeast-2" {
  source = "cowrie"
  region = "ap-northeast-2"
  cowrie_config = "${var.cowrie_config}"
  spot_price = "${module.pricing.spot["ap-northeast-2"]}"
  instance_count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ssh_public_key = "${module.cowrie-global.public_key}"
  ssh_private_key = "${module.cowrie-global.private_key}"
}

module "cowrie-ap-southeast-1" {
  source = "cowrie"
  region = "ap-southeast-1"
  cowrie_config = "${var.cowrie_config}"
  spot_price = "${module.pricing.spot["ap-southeast-1"]}"
  instance_count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ssh_public_key = "${module.cowrie-global.public_key}"
  ssh_private_key = "${module.cowrie-global.private_key}"
}

module "cowrie-ap-southeast-2" {
  source = "cowrie"
  region = "ap-southeast-2"
  cowrie_config = "${var.cowrie_config}"
  spot_price = "${module.pricing.spot["ap-southeast-2"]}"
  instance_count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ssh_public_key = "${module.cowrie-global.public_key}"
  ssh_private_key = "${module.cowrie-global.private_key}"
}

module "cowrie-ap-south-1" {
  source = "cowrie"
  region = "ap-south-1"
  cowrie_config = "${var.cowrie_config}"
  spot_price = "${module.pricing.spot["ap-south-1"]}"
  instance_count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ssh_public_key = "${module.cowrie-global.public_key}"
  ssh_private_key = "${module.cowrie-global.private_key}"
}

module "cowrie-sa-east-1" {
  source = "cowrie"
  region = "sa-east-1"
  cowrie_config = "${var.cowrie_config}"
  spot_price = "${module.pricing.spot["sa-east-1"]}"
  instance_count = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ssh_public_key = "${module.cowrie-global.public_key}"
  ssh_private_key = "${module.cowrie-global.private_key}"
}