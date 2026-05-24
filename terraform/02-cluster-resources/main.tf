provider "aws" {
  region = var.region
}

# Look up the cluster that 01-cluster created. Failing here means 01-cluster
# hasn't been applied yet (or cluster_name doesn't match).
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

locals {
  oidc_provider_url_no_scheme = replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")

  tags = {
    Project   = "claude-debug-demo"
    ManagedBy = "terraform"
  }
}
