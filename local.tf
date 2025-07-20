locals {
  project = "myapp"         # Or whatever your app/project name is
  env     = "dev"           # Or "prod", "staging", etc.

  prefix  = "${local.project}-${local.env}"
}