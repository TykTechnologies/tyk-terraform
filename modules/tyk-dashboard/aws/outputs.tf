output "dns_name" {
  value = "${aws_lb.lb.dns_name}"
}

output "zone_id" {
  value = "${aws_lb.lb.zone_id}"
}

output "lb_id" {
  value = "${aws_lb.lb.id}"
}

output "lb_sg_id" {
  value = "${aws_security_group.lb_sg.id}"
}

output "sg_id" {
  value = "${aws_security_group.instance_sg.id}"
}

output "asg_name" {
  value = "${module.asg.this_autoscaling_group_name}"
}

output "asg_arn" {
  value = "${module.asg.this_autoscaling_group_arn}"
}
