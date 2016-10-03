_       = require 'lodash'
async   = require 'async'
{exec}  = require 'child_process'
request = require 'request'
url   = require 'url'
EtcdManager = require './etcd-manager'
TravisStatusModel = require './travis-status-model'
debug   = require('debug')('deployinate-service:deployinate-model')

class DeploymentModel
  constructor: (options) ->
    {@repository, @docker_url, @tag} = options
    {@ETCDCTL_PEERS} = options
    {@GOVERNATOR_MAJOR_URL, @GOVERNATOR_MINOR_URL, @GOVERNATOR_SWARM_URL} = options
    {@TRAVIS_PRO_URL,@TRAVIS_ORG_URL} = options
    {@TRAVIS_PRO_TOKEN,@TRAVIS_ORG_TOKEN} = options
    throw new Error('repository is required') unless @repository?
    throw new Error('docker_url is required') unless @docker_url?
    throw new Error('tag is required') unless @tag?
    throw new Error('ETCDCTL_PEERS is required') unless @ETCDCTL_PEERS?
    throw new Error('GOVERNATOR_MAJOR_URL is required') unless @GOVERNATOR_MAJOR_URL?
    throw new Error('GOVERNATOR_SWARM_URL is required') unless @GOVERNATOR_SWARM_URL?
    throw new Error('GOVERNATOR_MINOR_URL is required') unless @GOVERNATOR_MINOR_URL?
    throw new Error('TRAVIS_PRO_URL is required') unless @TRAVIS_PRO_URL?
    throw new Error('TRAVIS_PRO_TOKEN is required') unless @TRAVIS_PRO_TOKEN?
    throw new Error('TRAVIS_ORG_URL is required') unless @TRAVIS_ORG_URL?
    throw new Error('TRAVIS_ORG_TOKEN is required') unless @TRAVIS_ORG_TOKEN?
    @repositoryDasherized = @repository?.replace '/', '-'

  _unprocessableError: (message) =>
    error = new Error message
    error.code = 422
    return error

  _preconditionError: (message) =>
    error = new Error message
    error.code = 412
    return error

  create: (callback) =>
    return callback @_unprocessableError("invalid repository: #{@repository}") unless @repository?
    return callback @_unprocessableError("invalid docker_url: #{@docker_url}") unless @docker_url?
    return callback @_unprocessableError("invalid tag: #{@tag}") unless @tag?

    @_getTravisBuildStatus (error, passed) =>
      return callback error if error?
      unless passed
        @_setKey "#{@repository}/status/travis", "build failed: #{@tag}"
        callback @_preconditionError "travis build failed: #{@tag}"
        return

      async.series [
        async.apply @_setKey, "#{@repository}/status/travis", "build successful: #{@tag}"
        @_postGovernatorMajor
        @_postGovernatorMinor
        @_postGovernatorSwarm
      ], callback

  _getTravisBuildStatus: (callback=->) =>
    travisStatus = new TravisStatusModel {
      @repository
      @tag
      @TRAVIS_PRO_URL
      @TRAVIS_ORG_URL
      @TRAVIS_PRO_TOKEN
      @TRAVIS_ORG_TOKEN
    }

    @_setKey "#{@repository}/status/travis", "checking: #{@tag}", =>
      travisStatus.getStatus callback

  _setKey: (key, value, callback=->) =>
    debug 'setKey', key, value
    etcdManager = new EtcdManager {@ETCDCTL_PEERS}
    etcd = etcdManager.getEtcd()
    etcd.set key, value, callback

  _postGovernatorMinor: (callback) =>
    @_postGovernator uri: @GOVERNATOR_MINOR_URL, callback

  _postGovernatorMajor: (callback) =>
    @_postGovernator uri: @GOVERNATOR_MAJOR_URL, callback

  _postGovernatorSwarm: (callback) =>
    @_postGovernator uri: @GOVERNATOR_SWARM_URL, callback

  _postGovernator: ({uri}, callback) =>
    options =
      uri: '/deployments'
      baseUrl: uri
      json:
        etcdDir: "/#{@repository}"
        dockerUrl: "#{@docker_url}:#{@tag}"

    request.post options, (error, response) =>
      return callback error if error?
      unless response.statusCode == 201
        host = 'unknown'
        try
          {host} = url.parse(uri)
        error = new Error("Expected to get a 201, got an #{response.statusCode}. host: #{host}")
        error.code = response.code
        return callback error
      callback()

module.exports = DeploymentModel
