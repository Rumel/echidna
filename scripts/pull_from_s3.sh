#!/usr/bin/env bash
source .env

export AWS_CLI_AUTO_PROMPT=off
aws s3 cp s3://$S3_BUCKET/client_secrets.json client_secrets.json
aws s3 cp s3://$S3_BUCKET/config.yaml config.yaml
aws s3 cp s3://$S3_BUCKET/credentials.yaml credentials.yaml
aws s3 cp s3://$S3_BUCKET/.env .env 