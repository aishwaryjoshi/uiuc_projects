import boto3
import pymysql
import pandas as pd
import io
import logging
import os

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS Clients
s3_client = boto3.client("s3")

# Database connection details (Replace these with actual RDS details)
DB_HOST = "RDSENDPOINT"
DB_USER = "USERNAME"
DB_PASSWORD =  "PASSWORD"
DB_NAME = "DATABASENAME"
DB_PORT = 3306

# S3 bucket details
S3_BUCKET = "S3BUCKETNAME"
INPUT_FILE = "FILENAME"


def lambda_handler(event, context):
    """
    AWS Lambda handler that reads data from S3, processes it, and writes it to MySQL RDS.
    """
    try:
        logger.info(f"📥 Fetching file: {INPUT_FILE} from S3 bucket: {S3_BUCKET}")
        
        # Step 1: Fetch CSV file from S3
        try:
            s3_object = s3_client.get_object(Bucket=S3_BUCKET, Key=INPUT_FILE)
            file_content = s3_object["Body"].read()
            logger.info(f"✅ Successfully fetched {INPUT_FILE} from S3 (Size: {len(file_content)} bytes)")
        except Exception as e:
            logger.error(f"❌ Failed to fetch file from S3: {str(e)}")
            return {
                "statusCode": 500,
                "body": "Error: Could not fetch file from S3."
            }

        # Step 2: Load CSV into Pandas DataFrame
        try:
            df = pd.read_csv(io.BytesIO(file_content))
            logger.info(f"✅ Successfully loaded CSV into DataFrame ({df.shape[0]} rows, {df.shape[1]} columns)")
        except Exception as e:
            logger.error(f"❌ Failed to read CSV: {str(e)}")
            return {
                "statusCode": 500,
                "body": "Error: Could not read CSV."
            }

        # Step 3: Clean Data
        try:
            df_cleaned = df.dropna(subset=["ProductId", "UserId", "Score", "Time", "Summary", "Text"])
            df_cleaned["Time"] = pd.to_datetime(df_cleaned["Time"], unit="s")
            df_cleaned = df_cleaned.where(pd.notna(df_cleaned), None)  # Convert NaNs to None for MySQL
            logger.info(f"🧹 Data cleaned. {df_cleaned.shape[0]} rows remaining after cleaning.")
        except Exception as e:
            logger.error(f"❌ Data cleaning failed: {str(e)}")
            return {
                "statusCode": 500,
                "body": "Error: Data cleaning failed."
            }

        # Step 4: Connect to MySQL RDS
        try:
            connection = pymysql.connect(
                host=DB_HOST,
                user=DB_USER,
                password=DB_PASSWORD,
                database=DB_NAME,
                port=DB_PORT,
                cursorclass=pymysql.cursors.DictCursor,
                autocommit=True  # Ensures automatic commit
            )
            cursor = connection.cursor()
            logger.info("✅ Successfully connected to MySQL RDS.")
        except Exception as e:
            logger.error(f"❌ Failed to connect to RDS: {str(e)}")
            return {
                "statusCode": 500,
                "body": "Error: Could not connect to RDS."
            }

        # Step 5: Insert Data into MySQL
        try:
            insert_query = """
                INSERT INTO customer_reviews 
                (product_id, user_id, profile_name, helpfulness_numerator, helpfulness_denominator, score, review_time, summary, review_text) 
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """

            # Convert DataFrame to list of tuples
            records_to_insert = [
                (
                    row["ProductId"],
                    row["UserId"],
                    row.get("ProfileName", None),
                    row.get("HelpfulnessNumerator", 0),
                    row.get("HelpfulnessDenominator", 0),
                    row["Score"],
                    row["Time"],
                    row["Summary"],
                    row["Text"],
                )
                for _, row in df_cleaned.iterrows()
            ]

            batch_size = 500  # Reduce batch size to avoid MySQL overload
            for i in range(0, len(records_to_insert), batch_size):
                batch = records_to_insert[i : i + batch_size]

                # Ensure connection is still active
                if not connection.open:
                    logger.info("🔄 Reconnecting to MySQL RDS...")
                    connection.ping(reconnect=True)
                    cursor = connection.cursor()

                cursor.executemany(insert_query, batch)
                logger.info(f"✅ Inserted batch of {len(batch)} rows.")

            logger.info(f"✅ Successfully inserted {df_cleaned.shape[0]} rows into MySQL.")

        except Exception as e:
            logger.error(f"❌ Failed to insert data into RDS: {str(e)}")
            return {
                "statusCode": 500,
                "body": "Error: Failed to insert data into MySQL RDS."
            }

        return {
            "statusCode": 200,
            "body": f"✅ Successfully processed {df_cleaned.shape[0]} rows from S3 and stored in RDS!"
        }

    except Exception as e:
        logger.error(f"❌ Unexpected error: {str(e)}")
        return {
            "statusCode": 500,
            "body": f"Unexpected error occurred: {str(e)}"
        }

    finally:
        if "cursor" in locals():
            cursor.close()
        if "connection" in locals():
            connection.close()
            logger.info("🔗 Database connection closed.")
