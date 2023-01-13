#configure aws provider
provider "aws" {
  region = var.region
  profile = "mainuser"
}

#create VPC
###source = "git@github.com:azeezsalu/success-bank-terraform-project.git//modules/vpc"
module "vpc" {
  source                        = "../modules/vpc"
  region                        = var.region
  project_name                  = var.project_name
  vpc_cidr                      = var.vpc_cidr
  public_subnet_az1_cidr        = var.public_subnet_az1_cidr
  public_subnet_az2_cidr        = var.public_subnet_az2_cidr
  private_app_subnet_az1_cidr   = var.private_app_subnet_az1_cidr
  private_app_subnet_az2_cidr   = var.private_app_subnet_az2_cidr
  private_data_subnet_az1_cidr  = var.private_data_subnet_az1_cidr
  private_data_subnet_az2_cidr  = var.private_data_subnet_az2_cidr
}

#NATGATEWAY
module "natgateway" {
  source                        = "../modules/natgateway"
  vpc_id                        = module.vpc.vpc_id         
  public_subnet_az1_id         = module.vpc.public_subnet_az1_id
  public_subnet_az2_id         = module.vpc.public_subnet_az2_id
  private_app_subnet_az1_id    = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id    = module.vpc.private_app_subnet_az2_id
  private_data_subnet_az1_id   = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id   = module.vpc.private_data_subnet_az2_id
  internet_gateway              = module.vpc.internet_gateway
}

#SECURITY GROUP
module "securitygroup" {
  source                        = "../modules/securitygroup"
  vpc_id                        = module.vpc.vpc_id         
  ssh_location                  = "0.0.0.0/0"
  
}

#ECS task EXecution role and ECS
module "securitygroup" {
  source                              = "../modules/ecs"
  project_name                        = module.vpc.project_name
  ecs_task_execution_role_arn         = module.ecs_task_execution_role_arn
  container_image                     = var.container_image
  region                              = module.vpc.region
  private_app_subnet_az1_id           = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id           = module.vpc.private_app_subnet_az2_id
  ecs_security_group_id               = module.securitygroup.ecs_security_group_id
  alb_target_group_arn                = module.alb.alb_target_group_arn      
}

#ACM CERtificate
module "acm-certificate" {
  source                              = "../modules/acm-certificate"
  domain_name                         = var.domain_name          
  subject_alternative_names           = var.alternative_names
}

#alb
module "alb" {
  source                    = "../modules/alb"
  project_name              = module.vpc.project_name
  public_subnet_az1_id      = module.vpc.public_subnet_az1_id
  public_subnet_az2_id      = module.vpc.public_subnet_az2_id
  alb_security_group_id     = module.securitygroup.alb_security_group_id
  certificate_arn           = module.acm-certificate.certificate_arn
}

#RDS
module "rds" {
  source                           = "../modules/rds"
  vpc_id                           = module.vpc.vpc_id         
  ssh_location                     = "0.0.0.0/0"
  database_instance_class          = var.database_instance_class
  db_name                          = var.db_name
  db_password                      = var.db_password
  private_data_subnet_az1_id       = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id       = module.vpc.private_data_subnet_az2_id
  database_security_group_id       = module.securitygroup.database_security_group_id
  
}



