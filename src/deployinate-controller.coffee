_            = require 'lodash'
debug        = require('debug')('flow-deploy-service:flow-deploy-controller')

class DeployinateController
  constructor: (@meshbluOptions={}, dependencies={}) ->
    @DeployinateModel = dependencies.DeployinateModel || require './flow-deploy-model'

  rollback: (request, response) =>
    {flowId} = request.params
    @deployinateModel = new @DeployinateModel flowId
    @deployinateModel.rollback (error) ->
      return response.status(401).json(error: 'unauthorized') if error?.message == 'unauthorized'
      return response.status(502).send(error: error) if error?
      return response.status(204).end()

  deploy: (request, response) =>
    {flowId} = request.params
    @deployinateModel = new @DeployinateModel flowId
    @deployinateModel.deploy (error) ->
      return response.status(401).json(error: 'unauthorized') if error?.message == 'unauthorized'
      return response.status(502).send(error: error) if error?
      return response.status(204).end()

module.exports = DeployinateController
