resource "aws_iam_user" "k8s" {
  name = "k8s"
}

resource "aws_iam_access_key" "k8s" {
  user = "${aws_iam_user.k8s.name}"
}

resource "aws_iam_policy_attachment" "k8s-ec2" {
  name       = "test-attachment"
  users      = ["${aws_iam_user.k8s.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_policy_attachment" "k8s-route53" {
  name       = "test-attachment"
  users      = ["${aws_iam_user.k8s.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

resource "aws_iam_policy_attachment" "k8s-s3" {
  name       = "test-attachment"
  users      = ["${aws_iam_user.k8s.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_policy_attachment" "k8s-iam" {
  name       = "test-attachment"
  users      = ["${aws_iam_user.k8s.name}"]
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_policy_attachment" "k8s-vpc" {
  name       = "test-attachment"
  users      = ["${aws_iam_user.k8s.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}
