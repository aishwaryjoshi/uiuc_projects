# AWS ETL Pipeline Project – S3, Lambda, RDS, EC2

## 📌 Objective
This project demonstrates an end-to-end ETL workflow using AWS infrastructure. The pipeline extracts raw review data from S3, transforms it using a Python Lambda function, and loads it into a MySQL RDS database. An EC2 instance is used to validate the data.

---

## 🧱 Architecture

- **S3**: Stores raw CSV files.
- **Lambda**: Triggered on file upload, cleans and processes data with Pandas.
- **RDS (MySQL)**: Stores structured review data.
- **EC2**: Used to connect and query the RDS database for validation.

---

## 🛠 Infrastructure Setup (IaC)

Terraform is used to provision all AWS components:
- `S3 bucket` named `teamx-raw-bucket`
- `Lambda function` with S3 trigger and environment configs
- `RDS MySQL instance` with public access for testing
- `EC2 instance` (Amazon Linux 2) for running SQL queries
- `Security Groups` to allow MySQL and SSH traffic

Run the following to deploy:

```bash
terraform init
terraform apply
