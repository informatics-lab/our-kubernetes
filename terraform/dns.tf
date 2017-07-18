resource "aws_route53_zone" "k8s" {
  name = "k8s.informaticslab.co.uk"

  tags {
    Environment = "k8s"
  }
}

resource "aws_route53_record" "k8s-ns" {
  zone_id = "Z3USS9SVLB2LY1"
  name    = "k8s.informaticslab.co.uk"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.k8s.name_servers.0}",
    "${aws_route53_zone.k8s.name_servers.1}",
    "${aws_route53_zone.k8s.name_servers.2}",
    "${aws_route53_zone.k8s.name_servers.3}",
  ]
}
