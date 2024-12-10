resource "aws_ebs_volume" "gitaly" {
  availability_zone = var.az[0]
  size              = 200
  type              = "gp3"

  tags = {
    Name = "gitaly"
  }
}