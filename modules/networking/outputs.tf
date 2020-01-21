/*output "vpc" {
  value = module.vpc
}*/

output "sg" {
  value = {
   // db     = module.db_sg.security_group.id
    lambda = module.lambda_sg.security_group.id
  }
}