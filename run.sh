#!/usr/bin/env bash

docker run -it --rm \
  -v ${PWD}/credentials.yaml:/usr/src/app/credentials.yaml \
  -v ${PWD}/client_secrets.json:/usr/src/app/client_secrets.json \
  -v ${PWD}/config.yaml:/usr/src/app/config.yaml \
  -v ${PWD}/youtube.db:/usr/src/app/youtube.db \
  echidna