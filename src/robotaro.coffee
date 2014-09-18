# Copyright (c) 2014 sobataro <sobatarooo@gmail.com>
# Released under the MIT license
# http://opensource.org/licenses/mit-license.php

https = require("https")
CronJob = require("cron").CronJob
Time = require("time")(Date)
PullRequestChecker = require("./pull_request_checker")
url = require("url")
config = require("config")

# send `message` to slack
slackMessage = (message) ->
  console.log "send message to slack..."

  slackUrl = url.parse config.get("slack.url")
  options =
    hostname: slackUrl.hostname
    path: slackUrl.path + "?token=" + config.get("slack.token")
    method: "POST"

  request = https.request options, (response) ->
    response.on "data", (data) ->
      if data.toString() != "ok"
        console.log "error"
        console.log "statusCode: " + response.statusCode
      console.log "\treponse: " + data.toString()

  request.on "error", (error) ->
    console.error error
    # TODO: resend

  payload = JSON.stringify
    channel: config.get("slack.channel")
    username: config.get("slack.username")
    text: message
    mrkdwn: true
    parse: "full"
    unfurl_links: 1

  request.write payload
  request.end()

shellMessage = (message) ->
  console.log "shell: #{message.toString()}"

check = () ->
  now = new Date()
  now.setTimezone(config.get "cron.timezone")
  console.log now.toString()
  if process.env.NODE_ENV == "development"
    PullRequestChecker.check shellMessage
  else
    PullRequestChecker.check slackMessage

# check when program started
console.log "first pull requests check:"
check()

# start cron job
new CronJob(config.get("cron.jobDefinition"), check, null, true, config.get("cron.timezone"))
