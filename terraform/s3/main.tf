provider "aws" {
  region = "us-west-2"
}

resource "random_id" "my-random-id" {
  byte_length = 2
}


/*
The template below 
resource "aws_s3_bucket" "my-test-bucket" in this file is of older version registries
Now, this template does not support policies in json format within the same resource
instead we have to define individual resources to create and attach policies
*/

/* We have commented the older template so that it doesnot get executed
Instead we have added the new resources which are substitute to the following resource
*/

/*
resource "aws_s3_bucket" "my-test-bucket" {
  bucket = "${var.s3_bucket_name}-${random_id.my-random-id.dec}"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    transition {
      storage_class = "STANDARD_IA"
      days          = 30
    }
  }

  tags = {
    Name = "21-days-of-aws-using-terraform"
  }
}

*/

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.s3_bucket_name}-${random_id.my-random-id.dec}"
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
  bucket = aws_s3_bucket.bucket.bucket

  rule {
    id = "log"

    expiration {
      days = 90
    }

    filter {
      and {
        prefix = "log/"

        tags = {
          rule      = "log"
          autoclean = "true"
        }
      }
    }

    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
     }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }

  rule {
    id = "tmp"

    filter {
      prefix = "tmp/"
    }

    expiration {
      date = "2023-01-13T00:00:00Z"
    }

    status = "Enabled"
  }
}


resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}