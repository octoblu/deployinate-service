_            = require 'lodash'
debug        = require('debug')('deployinate-service:status-controller')

class StatusController
  constructor: (options, dependencies={}) ->
    {@ETCDCTL_PEERS} = options
    {@GOVERNATOR_MAJOR_URL, @GOVERNATOR_MINOR_URL} = options
    @StatusModel = dependencies.StatusModel || require './status-model'

  show: (req, res) =>
    {namespace, service} = req.params
    status = new @StatusModel {
      repository: "#{namespace}/#{service}"
      @ETCDCTL_PEERS
      @GOVERNATOR_MAJOR_URL
      @GOVERNATOR_MINOR_URL
    }
    status.get (error, statusInfo) ->
      return res.status(error.code ? 500).send(error: error.message) if error?
      return res.status(200).send statusInfo

module.exports = StatusController
