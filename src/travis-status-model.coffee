_       = require 'lodash'
request = require 'request'
async   = require 'async'
debug   = require('debug')('deployinate-service:travis-status-model')

class TravisStatusModel
  constructor: ({@repository, @tag}, dependencies={}) ->

  getStatus: (callback=->) =>
    async.parallel [
      async.apply @_getBuild, host: "api.travis-ci.org", token: process.env.TRAVIS_TOKEN
      async.apply @_getBuild, host: "api.travis-ci.com", token: process.env.TRAVIS_PRO_TOKEN
    ], (error, builds) =>
      return callback error if error?
      passed = _.first _.compact builds
      callback null, passed

  _getBuild: ({host, token}, callback) =>
    options =
      json: true
      headers:
        'User-Agent': 'Octoblu Deployinate/1.0.0'
        'Authorization': "token #{token}"

    request.get "https://#{host}/repos/#{@repository}/builds", options, (error, response, body) =>
      return callback error if error?
      debug "searching #{host} builds for #{@tag}"

      build = _.findWhere body, branch: @tag
      return callback null, false unless build?

      debug 'found build', build

      callback null, build.result == 0

module.exports = TravisStatusModel
