_       = require 'lodash'
async   = require 'async'
{exec}  = require 'child_process'
request = require 'request'
EtcdManager = require './etcd-manager'
DeployinateStatusModel = require './deployinate-status-model'
TravisStatusModel = require './travis-status-model'
debug   = require('debug')('deployinate-service:deployinate-model')

class DeploymentModel
  constructor: (options) ->
    {@repository, @docker_url, @tag, @GOVERNATOR_MINOR_URL, @ETCDCTL_PEERS} = options
    {@TRAVIS_PRO_URL,@TRAVIS_ORG_URL} = options
    {@TRAVIS_PRO_TOKEN,@TRAVIS_ORG_TOKEN} = options
    @repositoryDasherized = @repository?.replace '/', '-'

  create: (callback) =>
    return callback new Error("invalid repository: #{@repository}") unless @repository?
    return callback new Error("invalid docker_url: #{@docker_url}") unless @docker_url?
    return callback new Error("invalid tag: #{@tag}") unless @tag?

    @_getTravisBuildStatus (error, passed) =>
      return callback error if error?
      unless passed
        @_setKey "#{@repository}/current_step", 'travis status failed'
        callback new Error "travis status failed"
        return

      options =
        uri: @GOVERNATOR_MINOR_URL
        json:
          etcdDir: @repository
          dockerUrl: "#{@docker_url}:#{@tag}"

      request.post options, (error, response) =>
        return callback error if error?
        unless response.statusCode == 201
          error = new Error("Expected to get a 201, got an #{response.statusCode}")
          error.code = response.code
          return callback error
        callback()

  _getTravisBuildStatus: (callback=->) =>
    travisStatus = new TravisStatusModel {
      @repository
      @tag
      @TRAVIS_PRO_URL
      @TRAVIS_ORG_URL
      @TRAVIS_PRO_TOKEN
      @TRAVIS_ORG_TOKEN
    }
    @_setKey "#{@repository}/current_step", 'checking travis status', =>
      travisStatus.getStatus callback

  _setKey: (key, value, callback=->) =>
    debug 'setKey', key, value
    etcdManager = new EtcdManager {@ETCDCTL_PEERS}
    etcd = etcdManager.getEtcd()
    etcd.set key, value, callback

module.exports = DeploymentModel
