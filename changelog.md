# Change Log

## 1.0

Initial commit of presets module, creating:
* 128k mp3
* 192k mp3
* 720p mp4
* 1080p mp4

## 1.1

Add queue module, queue has notifications:
* COMPLETE/ERROR to SQS
* All to Cloudwatch logs

## 1.2

Queue module outputs policy for using MediaConvert queue

## 1.3

Use `triggers_replace` for presets module as `inputs` is not enough to re-run local-exec