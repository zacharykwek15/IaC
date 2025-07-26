locals {
  project = "zh"         # Or whatever your app/project name is
  env     = "ecr"           # Or "prod", "staging", etc.

  prefix  = "${local.project}-${local.env}"
}