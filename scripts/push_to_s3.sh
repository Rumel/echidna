#!/usr/bin/env bash
source .env

export AWS_CLI_AUTO_PROMPT=off

aws s3 cp client_secrets.json s3://$S3_BUCKET
aws s3 cp credentials.yaml s3://$S3_BUCKET
aws s3 cp .env s3://$S3_BUCKET

if [ -f "$XDG_CONFIG_HOME/echidna/config.yaml" ]; then
  aws s3 cp $XDG_CONFIG_HOME/echidna/config.yaml s3://$S3_BUCKET/config.yaml
fi

if [ -f "$HOME/.config/echidna/config.yaml" ]; then
  aws s3 cp $HOME/.config/echidna/config.yaml s3://$S3_BUCKET/config.yaml
fi

if [ -f "./config.yaml" ]; then
  aws s3 cp ./config.yaml s3://$S3_BUCKET/config.yaml
fi