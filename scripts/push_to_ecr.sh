#!/usr/bin/env bash
source .env

docker tag echidna "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/echidna:latest"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/echidna:latest