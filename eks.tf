## EKS Cluster with Terraform
provider "aws" {
    region = "eu-north-1"
}

# EKS Cluster IAM Role
resource "aws_iam_role" "cluster-role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster-role.name
}

# EKS Cluster
resource "aws_eks_cluster" "cluster1" {
  name = "cluster"
  vpc_config {
    subnet_ids = ["subnet-0b9025e22d7e25f49", "subnet-06332970fe73ef540"]
    security_group_ids = ["sg-01be39ca928b458c1"]
  }
  
  # Changed to API mode for proper node authentication
  access_config {
    authentication_mode = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }
  
  role_arn = aws_iam_role.cluster-role.arn
  
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy_attachment,
  ]   
}

# Node Group IAM Role
resource "aws_iam_role" "node_group_role" {
  name = "nodegroup_role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_ssm_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EKS Node Group
resource "aws_eks_node_group" "group1" {
  cluster_name    = aws_eks_cluster.cluster1.name
  node_group_name = "group1"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = ["subnet-0b9025e22d7e25f49", "subnet-06332970fe73ef540"]
  instance_types  = ["c7i-flex.large"]
  
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1    
  }
  
  update_config {
    max_unavailable = 1
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy,
    aws_eks_access_entry.node,
  ]
}

# Node Access Entry (EC2_LINUX type doesn't need policy association)
resource "aws_eks_access_entry" "node" {
  cluster_name  = aws_eks_cluster.cluster1.name
  principal_arn = aws_iam_role.node_group_role.arn
  type          = "EC2_LINUX"
  
  depends_on = [aws_eks_cluster.cluster1]
}

# Admin Access Entry
resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.cluster1.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
  
  depends_on = [aws_eks_cluster.cluster1]
}

resource "aws_eks_access_policy_association" "admin_policy" {
  cluster_name  = aws_eks_cluster.cluster1.name
  principal_arn = data.aws_caller_identity.current.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  
  access_scope {
    type = "cluster"
  }
  
  depends_on = [aws_eks_access_entry.admin]
}

data "aws_caller_identity" "current" {}
