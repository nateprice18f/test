resource "aws_iam_role" "gitlab-access" {
  name = "gitlab-access"

  assume_role_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Federated": aws_iam_openid_connect_provider.openid.arn
                },
                "Action": "sts:AssumeRoleWithWebIdentity",
                "Condition": {
                    "StringEquals": {
                        "${replace(aws_iam_openid_connect_provider.openid.url, "https://", "")}:sub": "system:serviceaccount:gitlab:aws-access"
                    }
                }
            }
        ]
    })
}

resource "aws_iam_role_policy" "gitlab-access" {
  name = "gitlab-access"
  role = aws_iam_role.gitlab-access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "s3:ListBucket",
            "s3:GetBucketLocation",
            "s3:ListBucketMultipartUploads"
        ]
        Effect   = "Allow"
        Resource = [
            aws_s3_bucket.gitlab-backups.arn,
            aws_s3_bucket.gitlab-registry.arn,
            aws_s3_bucket.gitlab-runner-cache.arn,
            aws_s3_bucket.gitlab-pseudo.arn,
            aws_s3_bucket.git-lfs.arn,
            aws_s3_bucket.gitlab-artifacts.arn,
            aws_s3_bucket.gitlab-uploads.arn,
            aws_s3_bucket.gitlab-packages.arn
        ]
      },
      {
        Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject",
            "s3:ListMultipartUploadParts",
            "s3:AbortMultipartUpload"
        ]
        Effect   = "Allow"
        Resource = [
            "${aws_s3_bucket.gitlab-backups.arn}/*",
            "${aws_s3_bucket.gitlab-registry.arn}/*",
            "${aws_s3_bucket.gitlab-runner-cache.arn}/*",
            "${aws_s3_bucket.gitlab-pseudo.arn}/*",
            "${aws_s3_bucket.git-lfs.arn}/*",
            "${aws_s3_bucket.gitlab-artifacts.arn}/*",
            "${aws_s3_bucket.gitlab-uploads.arn}/*",
            "${aws_s3_bucket.gitlab-packages.arn}/*"
        ]
      }
    ]
  })
}