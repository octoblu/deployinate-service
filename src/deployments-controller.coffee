_            = require 'lodash'
debug        = require('debug')('deployinate-service:deployment-controller')

class DeploymentsController
  constructor: (options, dependencies={}) ->
    {@ETCDCTL_PEERS} = options
    {@GOVERNATOR_MAJOR_URL, @GOVERNATOR_MINOR_URL} = options
    {@TRAVIS_ORG_URL, @TRAVIS_ORG_TOKEN, @TRAVIS_PRO_URL, @TRAVIS_PRO_TOKEN} = options

    @DeploymentModel = dependencies.DeploymentModel || require './deployment-model'

  create: (req, res) =>
    {repository, updated_tags, docker_url} = req.body
    tag = _.first updated_tags
    @deployment = new @DeploymentModel {
      repository
      docker_url
      tag
      @ETCDCTL_PEERS
      @GOVERNATOR_MAJOR_URL
      @GOVERNATOR_MINOR_URL
      @TRAVIS_PRO_URL
      @TRAVIS_ORG_URL
      @TRAVIS_PRO_TOKEN
      @TRAVIS_ORG_TOKEN
    }
    @deployment.create (error) ->
      return res.status(error.code ? 500).send(error.message) if error?
      return res.status(201).end()

module.exports = DeploymentsController
