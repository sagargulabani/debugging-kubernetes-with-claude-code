resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = module.vpc.private_subnets

  ami_type       = "AL2023_x86_64_STANDARD"
  instance_types = [var.node_instance_type]

  scaling_config {
    min_size     = 2
    max_size     = 4
    desired_size = 2
  }

  update_config {
    max_unavailable = 1
  }

  tags = local.tags

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
  ]
}

# EKS managed node groups do not propagate node-group tags to the underlying
# ASG, so we tag the ASG directly. Cluster Autoscaler's auto-discovery
# (autoDiscovery.clusterName) finds ASGs by these tags.
resource "aws_autoscaling_group_tag" "cas_enabled" {
  autoscaling_group_name = aws_eks_node_group.default.resources[0].autoscaling_groups[0].name

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_group_tag" "cas_cluster_owned" {
  autoscaling_group_name = aws_eks_node_group.default.resources[0].autoscaling_groups[0].name

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = false
  }
}
