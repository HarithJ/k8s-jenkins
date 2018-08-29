data "aws_iam_policy" "AdministratorAccess" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "AdministratorAccess-role-policy-attach" {
  role = "${aws_iam_role.jenkins-role.name}"
  policy_arn = "${data.aws_iam_policy.AdministratorAccess.arn}"
}

resource "aws_iam_role" "jenkins-role" {
  name = "jenkins-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins_profile"
  role = "${aws_iam_role.jenkins-role.name}"
}
