#!/usr/bin/env bash
source .env

export AWS_CLI_AUTO_PROMPT=off
aws s3 cp client_secrets.json s3://$S3_BUCKET
aws s3 cp config.yaml s3://$S3_BUCKET
aws s3 cp credentials.yaml s3://$S3_BUCKET
aws s3 cp .env s3://$S3_BUCKET