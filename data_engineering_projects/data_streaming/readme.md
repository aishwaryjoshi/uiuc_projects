# 🛍️ Real-Time Marketing Offers Pipeline (Mini Project 2)

## 📌 Project Overview
This project implements a real-time offer generation pipeline using AWS services. The system captures user browsing activity, detects intent in real time, and delivers personalized promotional offers. All browsing events and offers are stored for future querying and analysis.

---

## 🧱 Architecture Components

| AWS Service      | Purpose                                                             |
|------------------|---------------------------------------------------------------------|
| **Kinesis**      | Streams user click events in real time                             |
| **Lambda**       | Processes events and triggers offer generation                     |
| **DynamoDB**     | Stores browsing activity and offers                                |
| **S3**           | Archives all generated offers as JSON files                        |
| **Glue Crawler** | Catalogs S3 data for querying                                       |
| **Athena**       | Allows SQL-style querying of historical offers                     |

---

## ⚙️ Infrastructure as Code (Terraform)

Terraform provisions the entire architecture:
- Kinesis Stream (`BrowsingClickstream`)
- DynamoDB Tables:
  - `BrowsingEvents`
  - `Offers`
- S3 Bucket (`real-time-offers-archive`)
- Lambda Functions:
  - `IngestorLambda`: Kinesis → DynamoDB
  - `OfferGeneratorLambda`: DynamoDB Stream → Offers + S3

---

## 🧪 Behavior Simulation

A Python script (`browsing_simulator.py`) generates synthetic user browsing events and sends them to Kinesis, triggering the entire offer workflow.

---

## 📝 What To Do Before `terraform apply`

### 1. Create Lambda ZIPs  
Ensure the following files are in your project directory:

```bash
zip lambda_ingestor.zip IngestorLambda.py
zip lambda_offer_generator.zip OfferGeneratorLambda.py
```

### 2. Initialize and Apply Terraform
```bash
terraform init
terraform apply
```

### 3. Simulate Browsing Activity

Run the following command from AWS CloudShell or any environment with access to your AWS credentials:

```bash
python3 browsing_simulator.py
```