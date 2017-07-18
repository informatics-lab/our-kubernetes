resource "aws_s3_bucket" "k8s-config" {
  bucket = "informticslab-k8s-config"
  acl    = "private"

  tags {
    Name        = "informticslab-k8s-config"
    Environment = "k8s"
  }

  versioning {
    enabled = true
  }
}
