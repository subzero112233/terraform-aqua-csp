#################################################
# Create Record Set with ALIAS
#################################################
resource "aws_route53_record" "aqua" {
  zone_id = "${var.aqua_zone_id}"
  name    = "aqua"
  type    = "A"

  alias {
    name                   = "${aws_lb.lb.dns_name}"
    zone_id                = "${aws_lb.lb.zone_id}"
    evaluate_target_health = false
  }
}
