provider "aws" {
  region = "us-east-1"
}

# -----------------------------
# 1. Kinesis Stream
# -----------------------------
resource "aws_kinesis_stream" "clickstream" {
  name             = "BrowsingClickstream"
  shard_count      = 1
  retention_period = 24
}

# -----------------------------
# 2. DynamoDB Tables
# -----------------------------

resource "aws_dynamodb_table" "browsing_events" {
  name           = "BrowsingEvents"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  range_key      = "timestamp"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
}

resource "aws_dynamodb_table" "offers" {
  name           = "Offers"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  range_key      = "offer_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "offer_id"
    type = "S"
  }
}

# -----------------------------
# 3. S3 Bucket
# -----------------------------

resource "aws_s3_bucket" "offer_archive" {
  bucket = "real-time-offers-archive"
  force_destroy = true
}

# -----------------------------
# 4. IAM Role for Lambdas
# -----------------------------

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "lambda_basic_exec"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_inline" {
  name = "lambda_inline_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:*",
          "s3:*",
          "kinesis:*",
          "logs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# -----------------------------
# 5. Lambda Functions
# -----------------------------

resource "aws_lambda_function" "ingestor" {
  filename         = "lambda_ingestor.zip"
  function_name    = "IngestorLambda"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "IngestorLambda.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("lambda_ingestor.zip")
}

resource "aws_lambda_event_source_mapping" "kinesis_to_lambda" {
  event_source_arn  = aws_kinesis_stream.clickstream.arn
  function_name     = aws_lambda_function.ingestor.arn
  starting_position = "LATEST"
  batch_size        = 100
}

resource "aws_lambda_function" "offer_generator" {
  filename         = "lambda_offer_generator.zip"
  function_name    = "OfferGeneratorLambda"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "OfferGeneratorLambda.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("lambda_offer_generator.zip")
  timeout          = 60
}

resource "aws_lambda_event_source_mapping" "ddb_to_lambda" {
  event_source_arn  = aws_dynamodb_table.browsing_events.stream_arn
  function_name     = aws_lambda_function.offer_generator.arn
  starting_position = "LATEST"
}

# Glue Database
resource "aws_glue_catalog_database" "offers_db" {
  name = "offers_db"
}

# Glue Crawler
resource "aws_glue_crawler" "offers_crawler" {
  name     = "OffersCrawler"
  role     = "LabRole"  # Must exist in your AWS account

  database_name = aws_glue_catalog_database.offers_db.name
  table_prefix  = "offers_"

  s3_target {
    path = "s3://${aws_s3_bucket.offer_archive.bucket}/offers/"
  }

  schedule {
    schedule_expression = "cron(0/1 * * * ? *)"  # Every 1 minute
  }

  configuration = jsonencode({
    Version = 1.0,
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })

  depends_on = [aws_s3_bucket.offer_archive]
}
