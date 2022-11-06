# Echidna

![status badge](https://github.com/rumel/echidna/actions/workflows/build.yml/badge.svg?branch=master)


# What is Echidna?
Echidna is an app to update your youtube playlists. A config.yaml is used to specifiy the channels that you want to follow and the playlists that you want to update. Echidna will then check the channels for new videos and add them to the specified playlists. A filter can be applied to a channel to only add matching videos to the playlist.

# Requirements
* Google Cloud Project
  * [Youtube Data API needs to be enabled](https://developers.google.com/youtube/v3)
  * OAuth 2.0 Client IDs needs to generated and the client_secrets.json file needs to be downloaded
* AWS Account
  * AWS User with access to S3, DynamoDB and ECR
* Docker

# Building
* `./scripts/build.sh`

# Running
* `./scripts/run.sh`