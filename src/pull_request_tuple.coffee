# Copyright (c) 2014 sobataro <sobatarooo@gmail.com>
# Released under the MIT license
# http://opensource.org/licenses/mit-license.php

Q = require("q")
config = require("config")

class PullRequestTuple
  constructor: (issue, githubot) ->
    @issue = issue
    @_reposMustWatchStatuses = config.get("github.reposMustWatchStatuses")
    @_githubot = githubot

    @_lastComment = null
    @_lastCommentDate = new Date(0)
    @_lgtmCount = 0
    @_lastStatus = null

  fetch: () ->
    d = Q.defer()
    Q.when()
    .then () => @_fetchComment()
    .then () => @_fetchPullRequest()
    .then () => @_fetchStatuses()
    .done (tuple) ->
      process.stdout.write(".")
      d.resolve tuple
    d.promise

  _fetchComment: () ->
    d = Q.defer()
    if @issue.comments > 0
      @_githubot.get @issue.comments_url, (comments) =>
        @comments = comments
        d.resolve this
    else
      @comments = []
      d.resolve this
    d.promise

  _fetchPullRequest: () ->
    d = Q.defer()
    @_githubot.get @issue.pull_request.url, (pullRequest) =>
      @pullRequest = pullRequest
      d.resolve this
    d.promise

  _fetchStatuses: () ->
    d = Q.defer()
    if @_mustWatchStatuses()
      @_githubot.get @pullRequest.statuses_url, (statuses) =>
        @statuses = statuses
        d.resolve this
    else
      d.resolve this
    d.promise

  makeIndicators: () ->
    for comment in @comments
      date = new Date(comment.created_at)
      if comment.body? and @_lastCommentDate <= date
        @_lastComment = comment
        @_lastCommentDate = date
      if @_isLGTM comment
        @_lgtmCount = @_lgtmCount + 1
    if @_mustWatchStatuses()
      lastStatusUpdated = new Date(0)
      for status in @statuses
        date = new Date(status.updated_at)
        if lastStatusUpdated < date
          lastStatusUpdated = date
          @_lastStatus = status

  _mustWatchStatuses: () ->
    array = @issue.url.split("/")
    repo = array[array.length - 3] # https://api.github.com/repos/[org-name]/[repo-name]/issues/[number]
    @_reposMustWatchStatuses.indexOf(repo) >= 0

  _getLastCommenter: () ->
    @_lastComment?.user.login

  _getPullRequestAuthor: () ->
    @pullRequest?.user.login

  _isLastStatusSuccessOrPending: () ->
    return true if not @_mustWatchStatuses()
    state = @_lastStatus?.state
    state == "success" or state == "pending"

  # if PR is labeled as "wip" or "do not merge", it is ok to be ignored...
  _isWIP: () ->
    for label in @issue.labels
      l = label.name.toLowerCase().replace(/\ /g, "")
      return true if l == "wip" or l == "donotmerge" or l == "dontmerge"
    return @pullRequest.title.toLowerCase().search(/wip/) > -1

  _isLGTM: (comment) ->
    comment?.body?.toLowerCase().replace(/(.)\1{2,}/gi, "$1").replace(/\s/g, "")
    .search(/lgtm|loksgodtome|ｌｇｔｍ/) > -1

  _isOld: (date) ->
    return true if not date?
    now = new Date()
    now - date >= config.get("waitAndSeeMinutes") * 60 * 1000

  # check if this PR has ignored and not commented
  isNotCommented: () ->
    @comments?.length == 0 and not @_isWIP() and @_isLastStatusSuccessOrPending()

  # check if this PR has two or more LGTM and last comment is LGTM, but is not merged
  isUnmergedLGTM: () ->
    @_lgtmCount >= 2 and not @_isWIP() and @_isLastStatusSuccessOrPending()

  # check if this PR has any comments, but seems to be ignored
  isHalfwayReviewedAndForgotten: () ->
    @comments?.length > 0 and @_isOld(@_lastCommentDate) and not @_isWIP() and @_isLastStatusSuccessOrPending()

  # check if this PR is conflicting or not
  isConflicting: () ->
    @pullRequest.mergeable == false and not @_isWIP()

  # text formatter

  makeReplyToPRCreaterCommenterText: () ->
    lastCommenter = @_getLastCommenter()
    prAuthor = @_getPullRequestAuthor()
    return "@channel" if lastCommenter == prAuthor
    return "@#{lastCommenter} @#{prAuthor}"

  makeReplyToPRCreaterText: () ->
    "@#{@_getPullRequestAuthor()}"

  makeDescriptionText: () ->
    "#{@pullRequest.title} (#{@pullRequest.html_url})"

module.exports = PullRequestTuple
