_            = require 'lodash'
debug        = require('debug')('deployinate-service:deployinate-controller')

class DeployinateController
  constructor: (options, dependencies={}) ->
    {@ETCDCTL_PEERS} = options
    {@TRAVIS_ORG_URL, @TRAVIS_ORG_TOKEN, @TRAVIS_PRO_URL, @TRAVIS_PRO_TOKEN} = options
    @DeployinateModel = dependencies.DeployinateModel || require './deployinate-model'
    @DeployinateStatusModel = dependencies.DeployinateStatusModel || require './deployinate-status-model'
    @DeployinateRollbackModel = dependencies.DeployinateRollbackModel || require './deployinate-rollback-model'

  deploy: (request, response) =>
    {repository, updated_tags, docker_url} = request.body
    tag = _.first updated_tags
    @deployinateModel = new @DeployinateModel {
      repository
      docker_url
      tag
      @ETCDCTL_PEERS
      @TRAVIS_ORG_URL
      @TRAVIS_ORG_TOKEN
      @TRAVIS_PRO_URL
      @TRAVIS_PRO_TOKEN
    }
    @deployinateModel.deploy (error) ->
      return response.status(422).send(error: error.message) if error?
      return response.status(201).end()

  deployWorker: (request, response) =>
    {repository, updated_tags, docker_url} = request.body
    tag = _.first updated_tags
    @deployinateModel = new @DeployinateModel repository, docker_url, tag
    @deployinateModel.deployWorker (error) ->
      return response.status(422).send(error: error.message) if error?
      return response.status(201).end()

  getStatus: (request, response) =>
    {namespace, service} = request.params
    statusModel = new @DeployinateStatusModel "#{namespace}/#{service}"
    statusModel.getStatus (error, statusInfo) ->
      return response.status(422).send(error: error.message) if error?
      return response.status(200).send statusInfo

  rollback: (request, response) =>
    {namespace, service} = request.params
    rollbackModel = new @DeployinateRollbackModel "#{namespace}/#{service}"
    rollbackModel.rollback (error) ->
      return response.status(422).send(error: error.message) if error?
      return response.status(201).end()

module.exports = DeployinateController
