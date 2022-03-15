provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudtrail" "my-demo-cloudtrail" {
  name                          = "${var.cloudtrail_name}"
  s3_bucket_name                = "${aws_s3_bucket.s3_bucket_name.id}"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
}

/*
The template below 
resource "aws_s3_bucket" "s3_bucket_name" in this file is of older version registries
Now, this template does not support policies in json format within the same resource
instead we have to define individual resources to create and attach policies
*/

/* We have commented the older template so that it doesnot get executed
Instead we have added the new resources which are substitute to the following resource
*/

/* resource "aws_s3_bucket" "s3_bucket_name" {
  bucket = "${var.s3_bucket_name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
{
   "Sid": "AWSCloudTrailAclCheck",
   "Effect": "Allow",
   "Principal": {
      "Service": "cloudtrail.amazonaws.com"
},
 "Action": "s3:GetBucketAcl",
 "Resource": "arn:aws:s3:::s3-cloudtrail-bucket-with-terraform-code"
},
{
"Sid": "AWSCloudTrailWrite",
"Effect": "Allow",
"Principal": {
  "Service": "cloudtrail.amazonaws.com"
},
"Action": "s3:PutObject",
"Resource": "arn:aws:s3:::s3-cloudtrail-bucket-with-terraform-code/*",
"Condition": {
  "StringEquals": {
     "s3:x-amz-acl": "bucket-owner-full-control"
  }
}
  }
  ]
  }
  POLICY
}

*/
/* the template above created random suffixes to the bucket name, to avoid it
we use ### resource "random_id" ###
*/

resource "random_id" "my-random-id" {
  byte_length = 2
}

resource "aws_s3_bucket" "example" {
  bucket = "${var.s3_bucket_name}-${random_id.my-random-id.dec}"
}

/*
Attaching policy to bucket
*/

resource "aws_s3_bucket_policy" "trail" {
  bucket = "${aws_s3_bucket.example.id}"
  policy = "${data.aws_iam_policy_document.cloudtrail_log_access.json}"
}

/*
creating iam policy to access s3 bucket
*/

data "aws_iam_policy_document" "cloudtrail_log_access" {

  statement {
    sid       = "AWSCloudTrailAclCheck"
    actions   = ["s3:GetBucketAcl"]
    resources = ["${aws_s3_bucket.example.arn}"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    sid     = "AWSCloudTrailWrite"
    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.example.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}