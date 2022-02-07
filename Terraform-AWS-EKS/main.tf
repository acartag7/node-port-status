provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

data "aws_availability_zones" "azs" {
  state = "available"
}

resource "aws_key_pair" "test_key" {
  key_name   = "arnold-key"
  public_key = "********"
}