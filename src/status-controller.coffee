_            = require 'lodash'
debug        = require('debug')('deployinate-service:status-controller')

class StatusController
  constructor: (options, dependencies={}) ->
    {@GOVERNATOR_MAJOR_URL, @GOVERNATOR_MINOR_URL} = options
    {@ETCD_MAJOR_URI, @ETCD_MINOR_URI} = options
    throw new Error('ETCD_MAJOR_URI is required') unless @ETCD_MAJOR_URI?
    throw new Error('ETCD_MINOR_URI is required') unless @ETCD_MINOR_URI?
    throw new Error('GOVERNATOR_MAJOR_URL is required') unless @GOVERNATOR_MAJOR_URL?
    throw new Error('GOVERNATOR_MINOR_URL is required') unless @GOVERNATOR_MINOR_URL?
    @StatusModel = dependencies.StatusModel || require './status-model'

  show: (req, res) =>
    {namespace, service} = req.params
    status = new @StatusModel {
      repository: "#{namespace}/#{service}"
      @GOVERNATOR_MAJOR_URL
      @GOVERNATOR_MINOR_URL
      @ETCD_MAJOR_URI
      @ETCD_MINOR_URI
    }
    status.get (error, statusInfo) =>
      return res.status(error.code ? 500).send(error: error.message) if error?
      return res.status(200).send statusInfo

module.exports = StatusController
