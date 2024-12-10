resource "aws_s3_bucket" "gitlab-registry" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.region}-gitlab-registry"
  }

resource "aws_s3_bucket" "gitlab-runner-cache" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.region}-runner-cache"
}

resource "aws_s3_bucket" "gitlab-backups" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.region}-gitlab-backups"
}

resource "aws_s3_bucket" "gitlab-pseudo" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.region}-gitlab-pseudo"
}

resource "aws_s3_bucket" "git-lfs" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.region}-git-lfs"
}

resource "aws_s3_bucket" "gitlab-artifacts" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.region}-gitlab-artifacts"
}

resource "aws_s3_bucket" "gitlab-uploads" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.region}-gitlab-uploads"
 }

resource "aws_s3_bucket" "gitlab-packages" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.region}-gitlab-packages"
}
