# Copyright (c) 2014 sobataro <sobatarooo@gmail.com>
# Released under the MIT license
# http://opensource.org/licenses/mit-license.php

should = require('should')
PullRequestTuple = require('../bin/pull_request_tuple')

describe 'PullRequestTuple', () ->
  before () ->
    @makeStubPullRequestTuple = (issue, pullRequest, comments, statuses) ->
      t = new PullRequestTuple issue, null
      t.pullRequest = pullRequest
      t.comments = comments
      t.statuses = statuses
      t._reposMustWatchStatuses = []
      t._reposMustWatchStatuses.push if statuses?.length > 1
      t.makeIndicators()
      t

  describe 'fetch()', () ->
    it 'TODO'

  describe 'PR has no comments', () ->
    before () ->
      comments = []
      @pr = @makeStubPullRequestTuple(
        # issue
        comments: comments.length
        url: 'https://api.github.com/repos/[org-name]/[repo-name]/issues/[number]'
        labels: []
      ,
        # pullRequest
        title: 'Found a bug'
        comments: comments.length
        mergeable: true
      , comments, null)

    it 'isNotCommented()', () ->
      @pr.isNotCommented().should.true
    it 'isUnmergedLGTM()', () ->
      @pr.isUnmergedLGTM().should.false
    it 'isHalfwayReviewedAndForgotten()', () ->
      @pr.isHalfwayReviewedAndForgotten().should.false
    it 'isConflicting()', () ->
      @pr.isConflicting().false

  describe 'PR has a new comment', () ->
    before () ->
      now = new Date()
      comments = [
        {
          body: 'hoge',
          user:
            login: 'octocat'
          created_at: now.toISOString()
          updated_at: now.toISOString()
        }
      ]
      @pr = @makeStubPullRequestTuple(
        # issue
        comments: comments.length
        url: 'https://api.github.com/repos/[org-name]/[repo-name]/issues/[number]'
        labels: []
      ,
        # pullRequest
        title: 'Found a bug'
        comments: comments.length
        mergeable: true
      , comments, null)

    it 'isNotCommented()', () ->
      @pr.isNotCommented().should.false
    it 'isUnmergedLGTM()', () ->
      @pr.isUnmergedLGTM().should.false
    it 'isHalfwayReviewedAndForgotten()', () ->
      @pr.isHalfwayReviewedAndForgotten().should.false
    it 'isConflicting()', () ->
      @pr.isConflicting().false

  describe 'PR has an old comment', () ->
    before () ->
      epoch = new Date(0)
      comments = [
        {
          body: 'hoge',
          user:
            login: 'octocat'
          created_at: epoch.toISOString()
          updated_at: epoch.toISOString()
        }
      ]
      @pr = @makeStubPullRequestTuple(
        # issue
        comments: comments.length
        url: 'https://api.github.com/repos/[org-name]/[repo-name]/issues/[number]'
        labels: []
      ,
        # pullRequest
        title: 'Found a bug'
        comments: comments.length
        mergeable: true
      , comments, null)

    it 'isNotCommented()', () ->
      @pr.isNotCommented().should.false
    it 'isUnmergedLGTM()', () ->
      @pr.isUnmergedLGTM().should.false
    it 'isHalfwayReviewedAndForgotten()', () ->
      @pr.isHalfwayReviewedAndForgotten().should.true
    it 'isConflicting()', () ->
      @pr.isConflicting().false

  describe 'PR has two old LGTMs', () ->
    before () ->
      epoch = new Date(0)
      comments = [
        {
          body: 'LGTM',
          user:
            login: 'octocat'
          created_at: epoch.toISOString()
          updated_at: epoch.toISOString()
        }
        {
          body: 'Loooooooooooks GooooooooooD TOOOOOOOOOOOOOO MEEEEEEEEEE',
          user:
            login: 'octocat'
          created_at: epoch.toISOString()
          updated_at: epoch.toISOString()
        }
      ]
      @pr = @makeStubPullRequestTuple(
        # issue
        comments: comments.length
        url: 'https://api.github.com/repos/[org-name]/[repo-name]/issues/[number]'
        labels: []
      ,
        # pullRequest
        title: 'Found a bug'
        comments: comments.length
        mergeable: true
      , comments, null)

    it 'isNotCommented()', () ->
      @pr.isNotCommented().should.false
    it 'isUnmergedLGTM()', () ->
      @pr.isUnmergedLGTM().should.true
    it 'isHalfwayReviewedAndForgotten()', () ->
      @pr.isHalfwayReviewedAndForgotten().should.true
    it 'isConflicting()', () ->
      @pr.isConflicting().false

  describe 'unmergeable PR', () ->
    before () ->
      epoch = new Date(0)
      comments = [
        {
          body: 'LGTM',
          user:
            login: 'octocat'
          created_at: epoch.toISOString()
          updated_at: epoch.toISOString()
        }
        {
          body: 'lgtm',
          user:
            login: 'octocat'
          created_at: epoch.toISOString()
          updated_at: epoch.toISOString()
        }
      ]
      @pr = @makeStubPullRequestTuple(
        # issue
        comments: comments.length
        url: 'https://api.github.com/repos/[org-name]/[repo-name]/issues/[number]'
        labels: []
      ,
        # pullRequest
        title: 'Found a bug'
        comments: comments.length
        mergeable: false
      , comments, null)

    it 'isNotCommented()', () ->
      @pr.isNotCommented().should.false
    it 'isUnmergedLGTM()', () ->
      @pr.isUnmergedLGTM().should.true
    it 'isHalfwayReviewedAndForgotten()', () ->
      @pr.isHalfwayReviewedAndForgotten().should.true
    it 'isConflicting()', () ->
      @pr.isConflicting().true
