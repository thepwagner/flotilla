variable "environment" {
  default = "develop"
  description = "Name of environment. i.e. test, staging, production."
}

variable "region" {
  default = "us-east-1"
  description = "Region to deploy a scheduler into."
}

variable "account_id" {
  default = "123456790"
  description = "AWS account id."
}

variable "flotilla_domain" {
  default = "mycloudand.me"
  description = "Domain name for services."
}

variable "flotilla_regions" {
  default = "us-east-1"
  description = "Region(s) to be scheduled, space delimited."
}

variable "flotilla_container" {
  default = "pwagner/flotilla"
  description = "Flotilla container version to use."
}

variable "instance_type" {
  default = "t2.nano"
  description = "Instance type for scheduler."
}

variable "ami" {
  default = "ami-1a642670"
  description = "AMI for scheduler instances."
}

variable "az1" {
  default = "us-east-1a"
  description = "First AZ."
}
variable "az2" {
  default = "us-east-1b"
  description = "Second AZ."
}
variable "az3" {
  default = "us-east-1c"
  description = "Third AZ."
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "vpc" {
  cidr_block = "192.168.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
    Name = "${var.environment}-scheduler-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.environment}-scheduler-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "${var.environment}-scheduler-public"
  }
}

resource "aws_subnet" "public01" {
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "${var.az1}"
  cidr_block = "192.168.1.0/24"
  tags {
    Name = "${var.environment}-scheduler-public-01"
  }
}

resource "aws_route_table_association" "public01-rta" {
  subnet_id = "${aws_subnet.public01.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_subnet" "public02" {
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "${var.az2}"
  cidr_block = "192.168.2.0/24"
  tags {
    Name = "${var.environment}-scheduler-public-02"
  }
}

resource "aws_route_table_association" "public02-rta" {
  subnet_id = "${aws_subnet.public02.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_subnet" "public03" {
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "${var.az3}"
  cidr_block = "192.168.3.0/24"
  tags {
    Name = "${var.environment}-scheduler-public-03"
  }
}

resource "aws_route_table_association" "public03-rta" {
  subnet_id = "${aws_subnet.public03.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "scheduler" {
  vpc_id = "${aws_vpc.vpc.id}"
  description = "Scheduler security group"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "scheduler" {
  name = "${var.environment}-scheduler"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudformation" {
  name = "FlotillaCloudFormation"
  role = "${aws_iam_role.scheduler.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":  {
    "Effect": "Allow",
    "Action": [
      "autoscaling:CreateAutoScalingGroup",
      "autoscaling:CreateLaunchConfiguration",
      "autoscaling:DeleteAutoScalingGroup",
      "autoscaling:DeleteLaunchConfiguration",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:UpdateAutoScalingGroup",
      "cloudformation:CreateStack",
      "cloudformation:DescribeStacks",
      "cloudformation:UpdateStack",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateInternetGateway",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSubnet",
      "ec2:DeleteVpc",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateRouteTable",
      "ec2:ModifyVpcAttribute",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancerListeners",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancerListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
      "iam:AddRoleToInstanceProfile",
      "iam:CreateRole",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:UpdateAssumeRolePolicy",
      "route53:ChangeResourceRecordSets",
      "route53:GetChange",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "sqs:CreateQueue",
      "sqs:DeleteQueue",
      "sqs:ListQueues"
    ],
    "Resource": "*"
  }
}
EOF
}

resource "aws_iam_role_policy" "dynamodb" {
  name = "FlotillaDynamoDb"
  role = "${aws_iam_role.scheduler.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":  [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/flotilla-${var.environment}-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:DeleteItem",
        "dynamodb:PutItem"
      ],
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/flotilla-${var.environment}-assignments"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/flotilla-${var.environment}-locks"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem"
      ],
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/flotilla-${var.environment}-regions"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:BatchWriteItem",
        "dynamodb:GetItem",
        "dynamodb:Scan"
      ],
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/flotilla-${var.environment}-services"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:BatchWriteItem",
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:Scan"
      ],
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/flotilla-${var.environment}-stacks"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:BatchWriteItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query"
      ],
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/flotilla-${var.environment}-status"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:BatchGetItem"
      ],
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_id}:table/flotilla-${var.environment}-users"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "queue" {
  name = "FlotillaQueue"
  role = "${aws_iam_role.scheduler.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":  {
    "Effect": "Allow",
    "Action": [
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage"
    ],
    "Resource": "arn:aws:sqs:${var.region}:${var.account_id}:flotilla-${var.environment}-scheduler"
  }
}
EOF
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.environment}-scheduler-profile"
  roles = ["${aws_iam_role.scheduler.name}"]
}

resource "aws_launch_configuration" "scheduler" {
  image_id = "${var.ami}"
  iam_instance_profile = "${aws_iam_instance_profile.profile.name}"
  security_groups = ["${aws_security_group.scheduler.id}"]
  instance_type = "${var.instance_type}"
  associate_public_ip_address = true
  user_data = <<EOF
#cloud-config

coreos:
  units:
    - name: flotilla.service
      command: start
      content: |
        [Unit]
        Description=Flotilla scheduler

        [Service]
        User=core
        Restart=always
        ExecStartPre=-/usr/bin/docker kill flotilla-scheduler
        ExecStartPre=-/usr/bin/docker rm flotilla-scheduler
        ExecStartPre=-/usr/bin/docker pull ${var.flotilla_container}
        ExecStart=/usr/bin/docker run --name flotilla-scheduler -e FLOTILLA_ENV=${var.environment} -e FLOTILLA_DOMAIN=${var.flotilla_domain} -e FLOTILLA_REGION="${var.flotilla_regions}" ${var.flotilla_container} scheduler
        ExecStop=/usr/bin/docker stop flotilla-scheduler

users:
  - name: core
    ssh-authorized-keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0b/hxxZesuGbCH7DBn299BZSwcviBFyPPpSm1+5ygO0j1qKoekt4Ou4PfHqBQtXuxyEKTPW1TXhUV764nwgUlPA0qs4tHB7NcKBiFCMr6I2RBohhiYk1Ed3XvvOR4W9Q3KrueBScXMLYBU0aKNpViR5i7WStkPsIemgE8uh73sDNPKRfzAuKz53qbqaqtEwPP8l25e85LfrCNOf4mBGTb1EO3GQccgXlbnOa3UDM1iQLRk/1bcSQN7ezrppGuvDkg4p73w+go34ZWCRUzWUcro0ZYUjty+GMzq6Chv8rdqc2MoCzuUZ356Nq3F0sbFVclGPNkEt46whyMDG43YY6j
  - name: _sshkeys
    homedir: /var/empty
    system: true
    primary-group: "docker"
    no-user-group: true
    shell: /sbin/nologin

write_files:
  - path: /etc/ssh/sshd_config
    permissions: 0600
    owner: root:root
    content: |
      UsePrivilegeSeparation sandbox
      Subsystem sftp internal-sftp
      PermitRootLogin no
      AllowUsers core
      PasswordAuthentication no
      ChallengeResponseAuthentication no
      AuthorizedKeysCommand /bin/docker run --rm ${var.flotilla_container} keys -r ${var.region}
      AuthorizedKeysCommandUser _sshkeys
EOF
}

resource "aws_autoscaling_group" "scheduler" {
  min_size = 1
  max_size = 1
  desired_capacity = 1
  health_check_type = "EC2"
  launch_configuration = "${aws_launch_configuration.scheduler.id}"
  vpc_zone_identifier = ["${aws_subnet.public01.id}", "${aws_subnet.public02.id}", "${aws_subnet.public03.id}"]

  tag {
    key = "Name"
    value = "${var.environment}-scheduler"
    propagate_at_launch = true
  }
}