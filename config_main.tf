provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "my-config" {
  name = "config-example"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "my-config" {
  role       = "${aws_iam_role.my-config.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
  depends_on = [aws_s3_bucket_policy.trail]
}
resource "random_id" "my-random-id" {
  byte_length = 2
}

resource "aws_s3_bucket" "my-config" {
  bucket = "${var.s3_bucket_name}-${random_id.my-random-id.dec}"
  lifecycle {
prevent_destroy = false
}
}
resource "aws_s3_bucket_policy" "trail" {
  bucket = "${aws_s3_bucket.my-config.id}"
  policy = "${data.aws_iam_policy_document.config_access.json}"
}

data "aws_iam_policy_document" "config_access" {

  statement {
    sid       = ""
    actions   = ["s3:GetBucketAcl"]
    resources = ["${aws_s3_bucket.my-config.arn}"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }

  statement {
    sid     = ""
    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.my-config.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}
resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.my-config.id
  acl    = "private"
}
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.my-config.id
  versioning_configuration {
    status = "Enabled"
   }
}

resource "aws_config_configuration_recorder" "my-config" {
  name     = "config-example"
   role_arn = "${aws_iam_role.my-config.arn}"
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "my-config" {
  name           = "config-example"
  s3_bucket_name = "${aws_s3_bucket.my-config.bucket}"

  depends_on = [aws_config_configuration_recorder.my-config]
}

resource "aws_config_configuration_recorder_status" "config" {
  name       = "${aws_config_configuration_recorder.my-config.name}"
  is_enabled = true

  depends_on = [aws_config_delivery_channel.my-config]
}

resource "aws_config_config_rule" "instances_in_vpc" {
  name = "instances_in_vpc"

  source {
    owner             = "AWS"
    source_identifier = "INSTANCES_IN_VPC"
  }

  depends_on = [aws_config_configuration_recorder.my-config]
}

resource "aws_config_config_rule" "cloud_trail_enabled" {
  name = "cloud_trail_enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }
  input_parameters = <<EOF
{
  "s3BucketName": "cloudwatch-to-s3-logs"
 }
EOF

  depends_on = [aws_config_configuration_recorder.my-config]
}

resource "aws_config_config_rule" "s3_bucket_versioning_enabled" {
  name = "s3_bucket_versioning_enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_VERSIONING_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.my-config]
}

resource "aws_config_config_rule" "desired_instance_type" {
  name = "desired_instance_type"

  source {
    owner             = "AWS"
    source_identifier = "DESIRED_INSTANCE_TYPE"
  }

  input_parameters = <<EOF
{
  "instanceType" : "t2.micro"
}
EOF

  depends_on = [aws_config_configuration_recorder.my-config]
}
