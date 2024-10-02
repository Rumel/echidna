#!/usr/bin/env bash

docker run -rm \
  -v ${PWD}/credentials.yaml:/usr/src/app/credentials.yaml \
  -v ${PWD}/client_secrets.json:/usr/src/app/client_secrets.json \
  -v ${PWD}/config.yaml:/usr/src/app/config.yaml \
  -v ${PWD}/logs:/usr/src/app/logs \
  -v ${PWD}/.env:/usr/src/app/.env \
  echidna
