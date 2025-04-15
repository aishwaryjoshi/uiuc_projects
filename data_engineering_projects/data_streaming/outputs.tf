output "kinesis_stream_name" {
  value = aws_kinesis_stream.clickstream.name
}

output "s3_bucket" {
  value = aws_s3_bucket.offer_archive.bucket
}

output "dynamodb_browsing_events" {
  value = aws_dynamodb_table.browsing_events.name
}

output "dynamodb_offers" {
  value = aws_dynamodb_table.offers.name
}
