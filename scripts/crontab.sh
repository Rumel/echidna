#!/bin/bash
set -x

source ~/Code/echidna/.env

~/Code/echidna/scripts/auth_ecr.sh
~/Code/echidna/scriptes/pull_from_ecr.sh
~/Code/echidna/scripts/pull_from_s3.sh
~/Code/echidna/scripts/run.sh
