#static website s3 bucket
data "aws_iam_policy_document" "iam_policy_document" {
  statement {
    actions = [
      "s3:GetObject",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "${aws_s3_bucket.s3_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.iam_policy_document.json
}

resource "aws_s3_bucket" "s3_bucket" {
  acl           = "private"
  force_destroy = true
  provisioner "local-exec" {
    command = "sleep 15"
  }
}

resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.s3_bucket.bucket
  key    = "code.zip"
  source = "${path.cwd}/src/client/build.zip"
  etag = filemd5("${path.cwd}/src/client/build.zip")
}

module "unzipper" {
    //depends_on = [aws_s3_bucket_object.object]
    source = "github.com/scottwinkler/terraform-s3-unzip"
    src_bucket = aws_s3_bucket.s3_bucket.bucket
    src_bucket_arn = aws_s3_bucket.s3_bucket.arn
    delete_zip = true
}