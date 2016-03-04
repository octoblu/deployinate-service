_            = require 'lodash'
debug        = require('debug')('deployinate-service:schedule-controller')

class ScheduleController
  constructor: (options, dependencies={}) ->
    {@ETCDCTL_PEERS} = options
    {@GOVERNATOR_MAJOR_URL, @GOVERNATOR_MINOR_URL} = options
    {@TRAVIS_ORG_URL, @TRAVIS_ORG_TOKEN, @TRAVIS_PRO_URL, @TRAVIS_PRO_TOKEN} = options

    @DeploymentModel = dependencies.DeploymentModel || require './deployment-model'

  update: (req, res) =>
    {namespace, service} = req.params
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
    @deployment.schedule  (error) ->
      return res.status(error.code ? 500).send(error.message) if error?
      return res.status(201).end()

module.exports = ScheduleController
