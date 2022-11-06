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

# Config
```yaml
---
  playlists:
    - title: Highlights # Title of the playlist, doesn't need to match the real playlist title
      id: PLdP6kCUEAT1_PZxWWvTGsWi-YMw1bVGl2 # ID of the playlist
      order: date # Order of the playlist can be 'date' or 'title'. 'title' sorts by channel title and then date, while date is purely for date order.
    - title: Cooking
      id: PLdP6kCUEAT18C6Ah2FZF5h-oMtDDmQLXl
      order: title
  channels:
    - name: Huskers # Name of channel, doesn't need to actually match
      id: UCMqWeJDl7yjblwPKVNo4XfA # ID of channel
      filter: ((Football).*(Highlights))|((Highlights).*(Football))|((Volleyball).*(Highlights))|((Highlights).*(Volleyball))|((Basketball).*(Highlights))|((Highlights).*(Basketball)) # Regex filter to apply to videos, can be nil if all videos should be used
      max_results: 50  # Number of results to pull
      playlist_id: PLdP6kCUEAT1_PZxWWvTGsWi-YMw1bVGl2 # Playlist to add videos to
    - name: NHL
      id: UCqFMzb-4AUf6WAIbl132QKA
      filter: (Blues).*(Highlights)
      max_results: 50 
      playlist_id: PLdP6kCUEAT1_PZxWWvTGsWi-YMw1bVGl2
    - name: Adam Ragusea
      id: UC9_p50tH3WmMslWRWKnM7dQ
      filter: null
      max_results: 10
      playlist_id: PLdP6kCUEAT18C6Ah2FZF5h-oMtDDmQLXl
    - name: Brian Lagerstrom
      id: UCn5fhcGRrCvrmFibPbT6q1A
      filter: null
      max_results: 10
      playlist_id: PLdP6kCUEAT18C6Ah2FZF5h-oMtDDmQLXl
```