_            = require 'lodash'
debug        = require('debug')('deployinate-service:deployment-controller')

class DeploymentsController
  constructor: (options, dependencies={}) ->
    {@GOVERNATOR_MINOR_URL, @ETCDCTL_PEERS} = options
    {@TRAVIS_ORG_URL, @TRAVIS_ORG_TOKEN, @TRAVIS_PRO_URL, @TRAVIS_PRO_TOKEN} = options

    @DeploymentModel = dependencies.DeploymentModel || require './deployment-model'
    @DeployinateStatusModel = dependencies.DeployinateStatusModel || require './deployinate-status-model'
    @DeployinateRollbackModel = dependencies.DeployinateRollbackModel || require './deployinate-rollback-model'

  create: (req, res) =>
    {repository, updated_tags, docker_url} = req.body
    tag = _.first updated_tags
    @deployinateModel = new @DeploymentModel {
      repository
      docker_url
      tag
      @ETCDCTL_PEERS
      @GOVERNATOR_MINOR_URL
      @TRAVIS_PRO_URL
      @TRAVIS_ORG_URL
      @TRAVIS_PRO_TOKEN
      @TRAVIS_ORG_TOKEN
    }
    @deployinateModel.create (error) ->
      return res.status(422).send(error: error.message) if error?
      return res.status(201).end()

module.exports = DeploymentsController
