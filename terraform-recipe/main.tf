variable "instance_count" {
  description = "Number of instances to launch in each region"
  default = 3
}
variable "spot_prices" {
  type = "map"

  default = {

      ap-south-1 = 0.004300
      eu-west-3 = 0.004000
      eu-west-2 = 0.004000
      eu-west-1 = 0.003800
      ap-northeast-3 = 0.004600
      ap-northeast-2 = 0.004300
      ap-northeast-1 = 0.004600
      sa-east-1 = 0.005600
      ca-central-1 = 0.003800
      ap-southeast-1 = 0.004400
      ap-southeast-2 = 0.004400
      eu-central-1 = 0.004000
      us-east-1 = 0.003500
      us-east-2 = 0.003500
      us-west-1 = 0.004100
      us-west-2 = 0.003500

  }
}


module "cowrie-global" {
  source = "global"
  region = "us-east-1"
}

module "cowrie-us-east-1" {
  source = "cowrie"
  region = "us-east-1"
  spot_price = "${var.spot_prices["us-east-1"]}"
  instance_count = "${var.instance_count}"
}

module "cowrie-us-east-2" {
  source = "cowrie"
  region = "us-east-2"
  spot_price = "${var.spot_prices["us-east-2"]}"
  instance_count = "${var.instance_count}"
}

module "cowrie-us-west-1" {
  source = "cowrie"
  region = "us-west-1"
  spot_price = "${var.spot_prices["us-west-1"]}"
  instance_count = "${var.instance_count}"
}

module "cowrie-us-west-2" {
  source = "cowrie"
  region = "us-west-2"
  spot_price = "${var.spot_prices["us-west-2"]}"
  instance_count = "${var.instance_count}"
}

module "cowrie-ca-central-1" {
  source = "cowrie"
  region = "ca-central-1"
  spot_price = "${var.spot_prices["ca-central-1"]}"
  instance_count = "${var.instance_count}"
}

module "cowrie-eu-west-1" {
  source = "cowrie"
  region = "eu-west-1"
  spot_price = "${var.spot_prices["eu-west-1"]}"
  instance_count = "${var.instance_count}"
}

module "cowrie-eu-west-2" {
  source = "cowrie"
  region = "eu-west-2"
  spot_price = "${var.spot_prices["eu-west-2"]}"
  instance_count = "${var.instance_count}"
}

module "cowrie-eu-central-1" {
  source = "cowrie"
  region = "eu-central-1"
  spot_price = "${var.spot_prices["eu-central-1"]}"
  instance_count = "${var.instance_count}"
}

module "cowrie-ap-northeast-1" {
  source = "cowrie"
  region = "ap-northeast-1"
  spot_price = "${var.spot_prices["ap-northeast-1"]}"
  instance_count = "${var.instance_count}"
}

module "cowrie-ap-northeast-2" {
  source = "cowrie"
  region = "ap-northeast-2"
  spot_price = "${var.spot_prices["ap-northeast-2"]}"
  instance_count = "${var.instance_count}"
}

module "cowrie-ap-southeast-1" {
  source = "cowrie"
  region = "ap-southeast-1"
  spot_price = "${var.spot_prices["ap-southeast-1"]}"
  instance_count = "${var.instance_count}"
}

module "cowrie-ap-southeast-2" {
  source = "cowrie"
  region = "ap-southeast-2"
  spot_price = "${var.spot_prices["ap-southeast-2"]}"
  instance_count = "${var.instance_count}"
}

module "cowrie-ap-south-1" {
  source = "cowrie"
  region = "ap-south-1"
  spot_price = "${var.spot_prices["ap-south-1"]}"
  instance_count = "${var.instance_count}"
}

module "cowrie-sa-east-1" {
  source = "cowrie"
  region = "sa-east-1"
  spot_price = "${var.spot_prices["sa-east-1"]}"
  instance_count = "${var.instance_count}"
}
