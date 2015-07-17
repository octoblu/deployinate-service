_            = require 'lodash'
debug        = require('debug')('deployinate-service:deployinate-controller')

class DeployinateController
  constructor: (dependencies={}) ->
    @DeployinateModel = dependencies.DeployinateModel || require './deployinate-model'

  deploy: (request, response) =>
    {repository, updated_tags, docker_url} = request.body
    tag = _.first _.keys(updated_tags)
    @deployinateModel = new @DeployinateModel repository, docker_url, tag
    @deployinateModel.deploy (error) ->
      return response.status(401).json(error: 'unauthorized') if error?.message == 'unauthorized'
      return response.status(502).send(error: error) if error?
      return response.status(201).end()

module.exports = DeployinateController
