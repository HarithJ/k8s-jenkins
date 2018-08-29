variable "private_key_path" {}
variable "key_name" {}
variable "DOCKER_USER_ID" {}
variable "DOCKER_PASSWORD" {}
variable "CLUSTER_NAME" {}
variable "CLUSTER_ZONE" {}
variable "KOPS_STATE_STORE" {}

data "aws_availability_zones" "available" {}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "jenkins" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "jenkins"
  }
}

resource "aws_subnet" "jenkins-subnet" {
  vpc_id     = "${aws_vpc.jenkins.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "jenkins-subnet"
  }
}

resource "aws_internet_gateway" "jenkins-igw" {
  vpc_id = "${aws_vpc.jenkins.id}"

  tags {
    Name = "jenkins-igw"
  }
}

resource "aws_s3_bucket" "cluster_bucket" {
  bucket = "${var.KOPS_STATE_STORE}"
  acl    = "private"
  force_destroy = true

  tags {
    Name        = "cluster"
  }
}

resource "aws_security_group" "jenkins-sg" {
  name        = "jenkins"
  description = "Allow ssh and http"
  vpc_id      = "${aws_vpc.jenkins.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags {
    Name = "jenkins-sg"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = "${aws_vpc.jenkins.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.jenkins-igw.id}"
  }

  tags {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public-rt-assc" {
  subnet_id      = "${aws_subnet.jenkins-subnet.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}

data "aws_ami" "jenkins" {
  most_recent      = true

  filter {
    name   = "tag:name"
    values = ["jenkins*"]
  }
}

resource "aws_instance" "jenkins-instance" {
  ami           = "${data.aws_ami.jenkins.id}"
  instance_type = "t2.micro"
  key_name      = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.jenkins-sg.id}"]
  subnet_id = "${aws_subnet.jenkins-subnet.id}"
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.jenkins_profile.name}"

  connection {
    user = "ubuntu"
    private_key="${file(var.private_key_path)}"
    /*agent = true
    timeout = "3m"*/
  }

  provisioner "local-exec" {
    command = "echo ${aws_s3_bucket.cluster_bucket.id} >> private_ips.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "echo export DOCKER_USER_ID=${var.DOCKER_USER_ID} >> ~/.profile",
      "echo export DOCKER_PASSWORD=${var.DOCKER_PASSWORD} >> ~/.profile",
      "echo export CLUSTER_NAME=${var.CLUSTER_NAME} >> ~/.profile",
      "echo export CLUSTER_ZONE=${var.CLUSTER_ZONE} >> ~/.profile",
      "echo export KOPS_STATE_STORE=s3://${aws_s3_bucket.cluster_bucket.id} >> ~/.profile",
      "source /home/ubuntu/.profile",
      "exec /home/ubuntu/cluster.sh"
    ]
  }

  tags {
    Name = "Jenkins"
  }
}

resource "aws_eip" "jenkins_eip" {
  vpc = true

  instance                  = "${aws_instance.jenkins-instance.id}"
  depends_on                = ["aws_internet_gateway.jenkins-igw"]
}
