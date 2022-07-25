//# Route53 Zone Records
//resource "aws_route53_record" "main-tztest-com" {
//  zone_id = local.tztest_zone_id
//  name = "main"
//  type = "CNAME"
//  ttl = "300"
//  records = [aws_alb.main.dns_name]
//}
//
