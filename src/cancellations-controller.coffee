_            = require 'lodash'

class CancellationsController
  constructor: (options, dependencies={}) ->
    {@ETCDCTL_PEERS} = options
    {@GOVERNATOR_MAJOR_URL, @GOVERNATOR_MINOR_URL, @GOVERNATOR_SWARM_URL} = options

    @CancellationModel = dependencies.CancellationModel || require './cancellation-model'

  create: (req, res) =>
    {repository, updated_tags, docker_url} = req.body
    tag = _.first updated_tags
    @cancellation = new @CancellationModel {
      repository
      docker_url
      tag
      @ETCDCTL_PEERS
      @GOVERNATOR_MAJOR_URL
      @GOVERNATOR_MINOR_URL
      @GOVERNATOR_SWARM_URL
    }
    @cancellation.create (error) ->
      return res.status(error.code ? 500).send(error.message) if error?
      return res.status(201).end()

module.exports = CancellationsController
