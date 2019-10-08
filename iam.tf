#
# Create IAM Role
#

data "aws_iam_policy_document" "bigip_role" {
  version = "2012-10-17"
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bigip_role" {
  name               = format("%s-bigip-role", var.prefix)
  assume_role_policy = data.aws_iam_policy_document.bigip_role.json

  #   assume_role_policy = <<EOF
  # {
  #   "Version": "2012-10-17",
  #   "Statement": [
  #     {
  #       "Action": "sts:AssumeRole",
  #       "Principal": {
  #         "Service": "ec2.amazonaws.com"
  #       },
  #       "Effect": "Allow",
  #       "Sid": ""
  #     }
  #   ]
  # }
  # EOF

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_instance_profile" "bigip_profile" {
  name = format("%s-bigip-profile", var.prefix)
  role = aws_iam_role.bigip_role.name
}

data "aws_iam_policy_document" "bigip_policy" {
  version = "2012-10-17"
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      "arn:aws:secretsmanager:*:*:secret:${aws_secretsmanager_secret_version.bigip-pwd.arn}"
    ]
  }
}

resource "aws_iam_role_policy" "bigip_policy" {
  name   = format("%s-bigip-policy", var.prefix)
  role   = aws_iam_role.bigip_role.id
  policy = data.aws_iam_policy_document.bigip_policy.json
}

#   #   policy = <<EOF
#   # {
#   #   "Version": "2012-10-17",
#   #   "Statement": [
#   #     {
#   #       "Action": [
#   #         "Action": "secretsmanager:GetSecretValue"
#   #       ],
#   #       "Effect": "Allow",
#   #       "Resource": "arn:aws:secretsmanager:*:*:secret:${aws_secretsmanager_secret_version.bigip-pwd.arn}"
#   #     }
#   #   ]
#   # }
#   # EOF
# }
