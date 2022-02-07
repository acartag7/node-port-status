resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }

  ingress {
    from_port = 85
    to_port   = 85
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }
}

resource "aws_security_group" "worker_group_mgmt_two" {
  name_prefix = "worker_group_mgmt_two"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }

  ingress {
    from_port = 85
    to_port   = 85
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }

}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }
}

#Create Security Group for My Home
resource "aws_security_group" "ip_home" {
  name_prefix = "Home_IP"
  description = "From Home"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow traffic from Home"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["46.6.8.115/32"]
  }
  egress {
    description = "Allow traffic from Home"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["46.6.8.115/32"]
  }
}