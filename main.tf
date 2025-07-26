
#Need to create a VPC 

module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    name = "zh-vpc"
    cidr = "10.0.0.0/16"
    azs             = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]         #Creation of private subnet 
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]   #Creation of public subnet

    enable_nat_gateway   = false        #change to true if we need to establish nat gateway for private subnet access to internet

    tags = {
        Terraform = "true"
        environment ="dev"
        owner = "zh"
 }
}



resource "aws_ecr_repository" "ecr" {
  name         = "${local.prefix}-ecr"
  force_delete = true
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.9.0"

  cluster_name = "${local.prefix}-ecs"
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    "${local.prefix}-service" = { #task definition and service name -> #Change
      cpu    = 512
      memory = 1024
      container_definitions = {
        "myapp" = { #container name -> Change
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.prefix}-ecr:latest"
          port_mappings = [
            {
              containerPort = 8080
              protocol      = "tcp"
            }
          ]
        }
      }
      assign_public_ip                   = true
      deployment_minimum_healthy_percent = 100
      subnet_ids                   = var.public_subnets.ids #List of subnet IDs to use for your tasks
      security_group_ids           = [aws.security_group.ecs_sg.id] #Create a SG resource and pass it here
    }
  }
}

  
# Security group example
resource "aws_security_group" "ecs_sg" {
  name        = "${local.prefix}-ecs-sg"
  description = "Allow HTTP"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating a IAM role for github yaml file for credential purpose
resource "aws_iam_role" "github_oidc_deploy" {
  name = "github-oidc-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::255945442255:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:zacharykwek15/IaC:ref:refs/heads/main"
          }
        }
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_oidc_policy" {
  role       = aws_iam_role.github_oidc_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role_policy_attachment" "github_oidc_ecr" {
  role       = aws_iam_role.github_oidc_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "github_oidc_logs" {
  role       = aws_iam_role.github_oidc_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}










