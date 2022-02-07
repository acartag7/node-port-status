resource "aws_s3_bucket" "node-status-project" {
  bucket = "vmware-node-status-project"
  acl    = "public-read"
}

#Create ECR 
resource "aws_ecr_repository" "vmware-project-repo" {
  name                 = "node_port_status"
  image_tag_mutability = "MUTABLE"
}
resource "aws_ecr_repository" "vmware-project-repo-test" {
  name                 = "node_port_status_test"
  image_tag_mutability = "MUTABLE"
}