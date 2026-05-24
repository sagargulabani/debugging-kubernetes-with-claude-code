# IAM Role for Cluster Autoscaler via IRSA.
#
# DEMO NOTE — this policy is INTENTIONALLY BROKEN.
# It includes the read-only permissions Cluster Autoscaler needs to *evaluate*
# scale-up decisions, but OMITS the write permissions it needs to actually scale:
#
#     autoscaling:SetDesiredCapacity
#     autoscaling:TerminateInstanceInAutoScalingGroup
#     autoscaling:UpdateAutoScalingGroup
#     ec2:DescribeImages
#     ec2:GetInstanceTypesFromInstanceRequirements
#     eks:DescribeNodegroup
#
# This produces scenario 1's failure mode: CAS detects unschedulable pods,
# picks an ASG, then fails with AccessDenied when calling SetDesiredCapacity.
#
# Full correct policy reference:
# https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md

data "aws_iam_policy_document" "cluster_autoscaler_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url_no_scheme}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url_no_scheme}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  name               = "${var.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "cluster_autoscaler_broken" {
  statement {
    sid    = "ClusterAutoscalerReadOnly"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${var.cluster_name}-cluster-autoscaler"
  description = "Intentionally broken policy for Claude Code debugging demo — missing scale-up permissions"
  policy      = data.aws_iam_policy_document.cluster_autoscaler_broken.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}
