resource "aws_ecr_repository" "ecr_repo" {
  name                 = local.namespace
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
