module "labels" {
  source  = "../../terraform-aws-labels/modules"

  name        = var.name
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
  repository  = var.repository

}

# Module      : Route53
# Description : Create Route53 zone resource on AWS for creating private
resource "aws_route53_zone" "private" {
  count = var.private_enabled ? 1 : 0

  name          = var.domain_name
  comment       = var.comment
  force_destroy = var.force_destroy
  tags          = module.labels.tags
  vpc {
    vpc_id = var.vpc_id
  }
}

# Module      : Route53
# Description : Create Route53 zone resource on AWS for creating public
#               hosted zones.


resource "aws_route53_zone" "public" {
  count = var.public_enabled ? 1 : 0

  name              = var.domain_name
  delegation_set_id = var.delegation_set_id
  comment           = var.comment
  force_destroy     = var.force_destroy
  tags              = module.labels.tags
}

# Module      : Route53 Record create
# Description : Create Route53 record sets resource on AWS.
resource "aws_route53_record" "default" {
  count                            = var.record_enabled && length(var.ttls) > 0 ? length(var.ttls) : 0
  zone_id                          = var.zone_id != "" ? var.zone_id : (var.private_enabled ? aws_route53_zone.private.*.zone_id[0] : aws_route53_zone.public.*.zone_id[0])
  name                             = element(var.names, count.index)
  type                             = element(var.types, count.index)
  ttl                              = element(var.ttls, count.index)
  records                          = split(",", element(var.values, count.index))
  set_identifier                   = length(var.set_identifiers) > 0 ? element(var.set_identifiers, count.index) : ""
  health_check_id                  = length(var.health_check_ids) > 0 ? element(var.health_check_ids, count.index) : ""
  multivalue_answer_routing_policy = length(var.multivalue_answer_routing_policies) > 0 ? element(var.multivalue_answer_routing_policies, count.index) : null
  allow_overwrite                  = length(var.allow_overwrites) > 0 ? element(var.allow_overwrites, count.index) : false
}

# Module      : Route53 Record alias
# Description : Create Route53 record sets resource on AWS.
resource "aws_route53_record" "alias" {
  count                            = var.record_enabled && length(var.alias) > 0 && length(var.alias["names"]) > 0 ? length(var.alias["names"]) : 0
  zone_id                          = var.zone_id
  name                             = element(var.names, count.index)
  type                             = element(var.types, count.index)
  set_identifier                   = length(var.set_identifiers) > 0 ? element(var.set_identifiers, count.index) : ""
  health_check_id                  = length(var.health_check_ids) > 0 ? element(var.health_check_ids, count.index) : ""
  multivalue_answer_routing_policy = length(var.multivalue_answer_routing_policies) > 0 ? element(var.multivalue_answer_routing_policies, count.index) : null
  allow_overwrite                  = length(var.allow_overwrites) > 0 ? element(var.allow_overwrites, count.index) : false
  alias {
    name                   = length(var.alias) > 0 ? element(var.alias["names"], count.index) : ""
    zone_id                = length(var.alias) > 0 ? element(var.alias["zone_ids"], count.index) : ""
    evaluate_target_health = length(var.alias) > 0 ? element(var.alias["evaluate_target_healths"], count.index) : false
  }
}

# Module      : Route53
# Description : Associate domain name to public or private zone 
resource "aws_route53_zone_association" "default" {
  count   = var.enabled ? 1 : 0
  zone_id = var.private_enabled ? aws_route53_zone.private.*.zone_id[0] : aws_route53_zone.public.*.zone_id[0]
  vpc_id  = var.secondary_vpc_id
}