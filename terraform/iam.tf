resource "aws_iam_user" "diag_ecr_user" {
  name = "diag-ecr-user"
}

resource "aws_iam_role" "diag_fargate_role" {
  name = "diag-fargate-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = [
            "ecs.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        }
      },
    ]
  })
}


resource "aws_iam_user_policy" "diag_ecr_policy" {
  name = "diag-ecr-policy"
  user = aws_iam_user.diag_ecr_user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iam:PassRole",
        "iam:GetRole",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeServices",
        "ecs:UpdateService",
        "ecs:RegisterTaskDefinition",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetLifecyclePolicy",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_access_key" "diag_ecr_key" {
  user = aws_iam_user.diag_ecr_user.name
}

resource "aws_iam_role_policy" "diag_ecr_fargate_policy" {
  name = "fargate-execution-role"
  role = aws_iam_role.diag_fargate_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetLifecyclePolicy"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
