data "aws_availability_zones" "available" {}
/*
module "vpc" {
  source                           = "terraform-aws-modules/vpc/aws"
  version                          = "2.21.0"
  name                             = "${var.namespace}-vpc"
  cidr                             = "10.0.0.0/16"
  azs                              = data.aws_availability_zones.available.names
  private_subnets                  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  //public_subnets                   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets                 = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
  create_database_subnet_group     = true
}*/

resource "aws_default_vpc" "default" {
}

module "lambda_sg" {
  source = "scottwinkler/sg/aws"
  vpc_id = aws_default_vpc.default.id
  ingress_rules = []
}
/*
module "db_sg" {
  source = "scottwinkler/sg/aws"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [{
    port            = 3306
    security_groups = [module.lambda_sg.security_group.id]
  }]
}*/