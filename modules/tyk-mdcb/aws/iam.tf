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
  name               = "tyk_mdcb_instance_${random_id.iam_id.hex}"
  path               = "/system/"
  assume_role_policy = "${data.aws_iam_policy_document.instance_assume_role.json}"
}

resource "aws_iam_instance_profile" "default" {
  name = "tyk_mdcb_${random_id.iam_id.hex}"
  role = "${aws_iam_role.instance.name}"
}
