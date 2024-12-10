resource "kubernetes_namespace_v1" "gitlab" {
  metadata {
    name = "gitlab"
  }
}

resource "kubernetes_service_account_v1" "gitlab" {
  metadata {
    name      = "aws-access"
    namespace = "gitlab"

    labels = {
      "app.kubernetes.io/name" = "aws-access"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.gitlab-access.arn
    }
  }
}

resource "kubernetes_secret_v1" "gitlab-postgres" {
  metadata {
    name       = "gitlab-postgres"
    namespace  = "gitlab"
  }

  data = {
   psql-password = "p${random_password.db_password.result}"
  }
}

resource "kubernetes_secret_v1" "s3-storage-credentials" {
  metadata {
    name       = "s3-storage-credentials"
    namespace  = "gitlab"
  }

  data = {
    connection = data.template_file.rails-s3-yaml.rendered
  }
}

data "template_file" "rails-s3-yaml" {
  template = <<EOF
provider: AWS
region: ${var.region}

EOF
}

resource "kubernetes_secret_v1" "s3-registry-storage-credentials" {
  metadata {
    name       = "s3-registry-storage-credentials"
    namespace  = "gitlab"
  }

  data = {
    config = data.template_file.registry-s3-yaml.rendered
  }
}

data "template_file" "registry-s3-yaml" {
  template = <<EOF
s3:
    bucket: ${aws_s3_bucket.gitlab-registry.id}
    region: ${var.region}
    v4auth: true
EOF
}

resource "random_password" "shell-secret" {
  length = 12
  special = true
  upper = true
}

resource "kubernetes_secret_v1" "shell-secret" {
  metadata {
    name       = "shell-secret"
    namespace  = "gitlab"
  }

  data = {
    password = random_password.shell-secret.result
  }
}

resource "kubernetes_persistent_volume_v1" "gitaly" {
  metadata {
    name      = "gitaly-pv"
  }
  spec {
    capacity = {
      storage = "200Gi"
    }
    access_modes = ["ReadWriteOnce"]
    storage_class_name = "ebs-gp2"
    persistent_volume_source {
        aws_elastic_block_store {
            fs_type   = "ext4"
            volume_id = aws_ebs_volume.gitaly.id
        }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "gitaly" {
  metadata {
    name      = "repo-data-gitlab-gitaly-0"
    namespace = "gitlab"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = "ebs-gp2"
    resources {
      requests = {
        storage = "200Gi"
      }
    }
    volume_name = kubernetes_persistent_volume_v1.gitaly.id
  }
}

resource "kubernetes_storage_class" "gitaly" {
  metadata {
    name = "ebs-gp2"
  }
  storage_provisioner = "kubernetes.io/aws-ebs"
  reclaim_policy      = "Retain"

  parameters = {
    type = "gp2"
  }

  allowed_topologies {
    match_label_expressions {
      key = "failure-domain.beta.kubernetes.io/zone"
      values = var.az
    }
  }
}