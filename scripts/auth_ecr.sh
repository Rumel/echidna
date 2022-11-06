#!/usr/bin/env bash
source .env

AWS_CLI_AUTO_PROMPT=off aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com