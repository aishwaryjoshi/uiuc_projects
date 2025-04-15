provider "aws" {
  region = "us-east-1"
}

# S3 Bucket
resource "aws_s3_bucket" "raw_data_bucket" {
  bucket = "teamx-raw-bucket"
  force_destroy = true
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy_attach" {
  name       = "attach-lambda-basic-execution"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaBasicExecutionRole"
}

# Lambda Function
resource "aws_lambda_function" "etl_lambda" {
  function_name = "teamx_lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  timeout       = 300
  memory_size   = 1024

  filename         = "lambda_function_payload.zip"  # You must create this locally
  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  environment {
    variables = {
      DB_HOST     = aws_db_instance.reviews_db.address
      DB_USER     = "teamx"
      DB_PASSWORD = "TeamXPassword123!"
      DB_NAME     = "reviews"
      S3_BUCKET   = aws_s3_bucket.raw_data_bucket.bucket
    }
  }
}

# S3 Trigger for Lambda
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.raw_data_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.etl_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.etl_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.raw_data_bucket.arn
}

# RDS MySQL
resource "aws_db_instance" "reviews_db" {
  identifier         = "teamx-rds"
  allocated_storage  = 20
  engine             = "mysql"
  engine_version     = "8.0"
  instance_class     = "db.t3.micro"
  username           = "teamx"
  password           = "TeamXPassword123!"
  db_name            = "reviews"
  skip_final_snapshot = true
  publicly_accessible = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "teamx_db_sg"
  description = "Allow MySQL access"
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "ec2_client" {
  ami           = "ami-0c2b8ca1dad447f8a"  # Amazon Linux 2 (us-east-1)
  instance_type = "t2.micro"
  key_name      = "your-key-name"  # Replace with your SSH key
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  tags = {
    Name = "teamx-ec2"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y mysql
              EOF
}

# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  name        = "teamx_ec2_sg"
  description = "Allow SSH access"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
