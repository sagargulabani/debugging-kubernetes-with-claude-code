resource "aws_ecr_repository" "demo_api" {
  name                 = "${var.cluster_name}-demo-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = local.tags
}
