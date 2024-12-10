terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.34.0"
    }
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.devops.endpoint

  cluster_ca_certificate = base64decode(
    aws_eks_cluster.devops.certificate_authority[0].data
  )

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.devops.endpoint

    cluster_ca_certificate = base64decode(
        aws_eks_cluster.devops.certificate_authority[0].data
    )

    exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
        command     = "aws"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "public" {
  name = "${var.public_dns_name}."
}