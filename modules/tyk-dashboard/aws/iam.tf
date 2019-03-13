data "aws_iam_policy_document" "instance_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "random_id" "iam_id" {
  byte_length = 8
}

resource "aws_iam_role" "instance" {
  name               = "tyk_dashboard_instance_${random_id.iam_id.hex}"
  path               = "/system/"
  assume_role_policy = "${data.aws_iam_policy_document.instance_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "ssm_role_policy" {
  role       = "${aws_iam_role.instance.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"

  count = "${var.enable_ssm ? 1 : 0}"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_instance_role" {
  role       = "${aws_iam_role.instance.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"

  count = "${var.enable_cloudwatch_policy ? 1 : 0}"
}

resource "aws_iam_instance_profile" "default" {
  name = "tyk_dashboard_${random_id.iam_id.hex}"
  role = "${aws_iam_role.instance.name}"
}
