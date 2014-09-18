# Copyright (c) 2014 sobataro <sobatarooo@gmail.com>
# Released under the MIT license
# http://opensource.org/licenses/mit-license.php

Q = require("q")
config = require("config")
PullRequestTuple = require("./pull_request_tuple")

githubot = require("githubot")(
  logger: # dummy robot only has error logger
    error: (e) ->
      console.error e
, config.get("github"))

class PullRequestChecker
  @makePullRequestTuples: () ->
    console.log "fetching pull requests from github (it may take a while)"
    url = "orgs/#{config.get("github.orgName")}/issues?filter=all&state=open&per_page=100"
    d = Q.defer()
    githubot.get url, (issues) =>
      issuesWithPR = (issue for issue in issues when issue.pull_request? and issue.comments > 0)
      tuples = (new PullRequestTuple(i, githubot) for i in issuesWithPR)
      tuples = (t.fetch() for t in tuples)
      Q.allSettled(tuples).then (promises) =>
        console.log ''
        d.resolve (p.value for p in promises)
    d.promise

  @_makeMessage: (ignoredList, title, pullRequestFormatter) ->
    message = []
    if ignoredList.length > 0
      message.push title
      for t in ignoredList
        message.push pullRequestFormatter t
      message.push '' # section separator
    message

  @checkIssuesCommentsPullRequests: (pullRequestTuples) ->
    console.log "checking ignored pull requests"
    ignored  = (t for t in pullRequestTuples when t.isNotCommented())
    unmerged = (t for t in pullRequestTuples when t.isUnmergedLGTM())
    halfway  = (t for t in pullRequestTuples when t.isHalfwayReviewedAndForgotten())
    conflict = (t for t in pullRequestTuples when t.isConflicting())

    message = []

    message = message.concat @_makeMessage(ignored,
    "*誰もレビューしていないプルリクが #{ignored.length} 件ある、誰かレビューしてくだち* @channel",
    (t) -> t.makeDescriptionText())

    message = message.concat @_makeMessage(unmerged,
    "*LGTMなのにマージされていないプルリクが #{unmerged.length} 件あるっぽい*",
    (t) -> "#{t.makeDescriptionText()} #{t.makeReplyToPRCreaterCommenterText()}")

    message = message.concat @_makeMessage(halfway,
    "*レビューの途中で放置されているプルリクが #{halfway.length} 件あるかも？*",
    (t) -> "#{t.makeDescriptionText()} #{t.makeReplyToPRCreaterCommenterText()}")

    message = message.concat @_makeMessage(conflict,
    "*コンフリクトしているプルリクが #{conflict.length} 件あるぽ*",
    (t) -> "#{t.makeDescriptionText()} #{t.makeReplyToPRCreaterText()}")

    if message.length == 0
      message.push "放置されてそうなプルリクはない٩(๑❛ᴗ❛๑)۶"
    else if message.length > 20
      message.push "ワオ！大漁大漁！"
    else
      message.pop()

    console.log "done."
    message.join("\n")

  @check: (sendMessage) ->
    Q.when()
    .then @makePullRequestTuples
    .done (pullRequests) =>
      (t.makeIndicators() for t in pullRequests)
      sendMessage @checkIssuesCommentsPullRequests(pullRequests)

module.exports = PullRequestChecker
