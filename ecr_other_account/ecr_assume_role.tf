# This tf file should run on the other account, where the ECR is installed.
# Also, iam role for ecs has assume role policy which prerequisite and it already added on iam.tf and ecs.tf so no reference here.

# Though not discussed or created here, there are modifications required inside the ECR, mentioned here, on section 3: https://medium.com/miq-tech-and-analytics/cross-account-how-to-access-aws-container-registry-service-from-another-aws-account-using-iam-b372796ede14

variable "aqua_account_id" {
  description = "The account in which Aqua is installed on"
}

data "aws_iam_policy" "AmazonEC2ContainerRegistryReadOnly" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_policy_document" "trust_policy_ecr_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aqua_account_id}:root"]
    }

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecr_role" {
  name               = "ecr-role"
  assume_role_policy = "${data.aws_iam_policy_document.trust_policy_ecr_role.json}"
}

resource "aws_iam_policy_attachment" "ecr-role" {
  name       = "ecr-attachment"
  roles      = ["${aws_iam_role.ecr_role.name}"]
  policy_arn = "${data.aws_iam_policy.AmazonEC2ContainerRegistryReadOnly.arn}"
}
