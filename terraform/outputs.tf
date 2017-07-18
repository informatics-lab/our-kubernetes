output "k8s-access-key-id" {
  value = "${aws_iam_access_key.k8s.id}"
}

output "k8s-secret-access-key" {
  value = "${aws_iam_access_key.k8s.secret}"
}

output "k8s-state-bucket" {
  value = "${aws_s3_bucket.k8s-config.bucket}"
}

output "k8s-dns-zone" {
  value = "${aws_route53_zone.k8s.name}"
}
