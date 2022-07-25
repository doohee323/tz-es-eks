## [ ELB log ] ###########################################################################
resource "aws_s3_bucket" "elbaccess-bucket" {
  bucket = "elbaccess-bucket-${random_string.random.result}"
}

resource "aws_s3_bucket_policy" "allow_access_elbaccess-bucket" {
  bucket = aws_s3_bucket.elbaccess-bucket.id
  policy = data.aws_iam_policy_document.allow_access_elbaccess-bucket.json
}

data "aws_iam_policy_document" "allow_access_elbaccess-bucket" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.elbaccess-bucket.arn}/*",
    ]
  }
}

resource "aws_sqs_queue" "elbaccess-event-queue" {
  name = "elbaccess-event-queue"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:elbaccess-event-queue",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.elbaccess-bucket.arn}" }
      }
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_notification" "elbaccess_notification" {
  bucket = aws_s3_bucket.elbaccess-bucket.id
  queue {
    queue_arn     = aws_sqs_queue.elbaccess-event-queue.arn
    events        = ["s3:ObjectCreated:*"]
  }
}

## [ s3access log ] ###########################################################################
resource "aws_s3_bucket" "s3access-bucket" {
  bucket = "s3access-bucket-${random_string.random.result}"
}

resource "aws_s3_bucket_policy" "allow_access_s3access-bucket" {
  bucket = aws_s3_bucket.s3access-bucket.id
  policy = data.aws_iam_policy_document.allow_access_s3access-bucket.json
}

data "aws_iam_policy_document" "allow_access_s3access-bucket" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.s3access-bucket.arn}/*",
    ]
  }
}

resource "aws_sqs_queue" "s3access-event-queue" {
  name = "s3access-event-queue"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:s3access-event-queue",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.s3access-bucket.arn}" }
      }
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_notification" "s3access_notification" {
  bucket = aws_s3_bucket.s3access-bucket.id
  queue {
    queue_arn     = aws_sqs_queue.s3access-event-queue.arn
    events        = ["s3:ObjectCreated:*"]
  }
}

## [ cloudfront log ] ###########################################################################
resource "aws_s3_bucket" "cloudfront-bucket" {
  bucket = "cloudfront-bucket-${random_string.random.result}"
}

resource "aws_s3_bucket_policy" "allow_access_cloudfront-bucket" {
  bucket = aws_s3_bucket.cloudfront-bucket.id
  policy = data.aws_iam_policy_document.allow_access_cloudfront-bucket.json
}

data "aws_iam_policy_document" "allow_access_cloudfront-bucket" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.cloudfront-bucket.arn}/*",
    ]
  }
}

resource "aws_sqs_queue" "cloudfront-event-queue" {
  name = "cloudfront-event-queue"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:cloudfront-event-queue",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.cloudfront-bucket.arn}" }
      }
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_notification" "cloudfront_notification" {
  bucket = aws_s3_bucket.cloudfront-bucket.id
  queue {
    queue_arn     = aws_sqs_queue.cloudfront-event-queue.arn
    events        = ["s3:ObjectCreated:*"]
  }
}
