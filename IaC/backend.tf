terraform {
  backend "s3" {
    bucket = "techops-devops-s3"
    key    = "devops/gitlab/1/terraform-state"
    region = "us-east-1"
  }
}