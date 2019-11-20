data "aws_region" "current" {}

data "aws_ami" "bastion" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

data "aws_iam_policy_document" "sts" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "bastion" {
  # Add CloudWatch logging

  statement {
    actions = [
      "ec2:AssociateAddress",
      "ec2:DescribeAddresses",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "role" {
  name               = "c-${var.name}-BastionRole"
  assume_role_policy = data.aws_iam_policy_document.sts.json
}

resource "aws_iam_role_policy" "policy" {
  name   = "${var.name}-BastionPolicy"
  role   = aws_iam_role.role.name
  policy = data.aws_iam_policy_document.bastion.json
}

resource "aws_security_group" "sg" {
  name   = "${var.name}-bastion"
  vpc_id = var.vpc.id

  tags = {
    Name = "${var.name}-bastion"
  }
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.sg.id
  from_port         = "22"
  to_port           = "22"
  protocol          = "tcp"
  cidr_blocks       = var.whitelist
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  security_group_id = aws_security_group.sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.name}-bastion"
  role = aws_iam_role.role.name
}

resource "aws_eip" "ip" {
  count = var.max
  vpc   = true

  tags = {
    Name = "${var.name}-bastion-${count.index}"
  }
}

resource "spotinst_elastigroup_aws" "asg" {
  name                 = "${var.name}-bastion"
  product              = "Linux/UNIX"
  max_size             = var.max
  min_size             = var.min
  desired_capacity     = var.desired
  region               = data.aws_region.current.name
  subnet_ids           = var.public_subnets
  image_id             = data.aws_ami.ami.id
  iam_instance_profile = aws_iam_instance_profile.bastion.arn
  security_groups      = [aws_security_group.sg.id]
  enable_monitoring    = false
  ebs_optimized        = false

  #   user_data = <<EOF
  # #cloud-config
  # runcmd:
  #   - false %{for ip in aws_eip.ip.*.id~} || aws --region ${data.aws_region.current.name} ec2 associate-address --instance-id $(curl http://169.254.169.254/latest/meta-data/instance-id) --allocation-id ${ip} --allow-reassociation %{endfor~}
  # EOF

  user_data = templatefile("${path.module}/data/init.yaml", {
    ips    = aws_eip.ip.*.id,
    region = data.aws_region.current.name
  })

  instance_types_ondemand       = var.instance_types_ondemand
  instance_types_spot           = var.instance_types_spot
  instance_types_preferred_spot = var.instance_types_preferred_spot

  orientation          = "balanced"
  fallback_to_ondemand = false
  cpu_credits          = "unlimited"
  spot_percentage      = 100

  scaling_strategy {
    terminate_at_end_of_billing_hour = false
    termination_policy               = "default"
  }

  tags {
    key   = "Environment"
    value = terraform.workspace
  }

  tags {
    key   = "Name"
    value = "${var.name}-bastion"
  }

  lifecycle {
    ignore_changes = [
      desired_capacity,
    ]
  }
}
