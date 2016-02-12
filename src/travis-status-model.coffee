_       = require 'lodash'
request = require 'request'
async   = require 'async'
debug   = require('debug')('deployinate-service:travis-status-model')

class TravisStatusModel
  constructor: (options) ->
    {@repository, @tag} = options
    {@TRAVIS_PRO_URL, @TRAVIS_ORG_URL, @TRAVIS_ORG_TOKEN, @TRAVIS_PRO_TOKEN} = options

  getStatus: (callback) =>
    async.parallel [
      async.apply @_getBuild, baseUri: @TRAVIS_ORG_URL, token: @TRAVIS_ORG_TOKEN
      async.apply @_getBuild, baseUri: @TRAVIS_PRO_URL, token: @TRAVIS_PRO_TOKEN
    ], (error, builds) =>
      return callback error if error?
      passed = _.first _.compact builds
      callback null, passed

  _getBuild: ({baseUri, token}, callback) =>
    options =
      uri: "/repos/#{@repository}/builds"
      baseUrl: baseUri
      json: true
      headers:
        'User-Agent': 'Octoblu Deployinate/1.0.0'
        'Authorization': "token #{token}"

    request.get options, (error, response, body) =>
      return callback error if error?
      debug "searching #{baseUri} builds for #{@tag}"

      build = _.findWhere body, branch: @tag
      return callback null, false unless build?

      debug 'found build', build

      callback null, (_.isNull(build.result) || build.result == 0)

module.exports = TravisStatusModel
