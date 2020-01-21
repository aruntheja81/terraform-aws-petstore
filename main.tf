module "networking" {
  source    = "./modules/networking"
  namespace = var.namespace
}

module "database" {
  source       = "./modules/database"
  namespace    = var.namespace
  region       = var.region
  rds_user     = var.rds_user
  rds_password = var.rds_password
  //vpc          = module.networking.vpc
  sg           = module.networking.sg
}

module "lambda" {
  source       = "./modules/lambda"
  namespace    = var.namespace
  rds_user     = var.rds_user
  rds_password = var.rds_password
  rds_host     = module.database.rds_host
  rds_port     = module.database.rds_port
  rds_database = module.database.rds_database
  //vpc          = module.networking.vpc
  sg           = module.networking.sg
}

module "apigw" {
  source     = "./modules/apigw"
  namespace  = var.namespace
  lambda_arn = module.lambda.lambda_arn
}
/*
module "s3" {
  source     = "./modules/s3"
  namespace  = var.namespace
}*/