_                = require 'lodash'
url              = require 'url'
async            = require 'async'
request          = require 'request'
EtcdManager      = require './etcd-manager'
EtcdParserModel = require './etcd-parser-model'
debug   = require('debug')('deployinate-service:status-model')

class StatusModel
  constructor: (options) ->
    {@repository} = options
    {ETCDCTL_PEERS} = options
    {@GOVERNATOR_MAJOR_URL, @GOVERNATOR_MINOR_URL} = options
    throw new Error('repository is required') unless @repository?
    throw new Error('ETCDCTL_PEERS is required') unless ETCDCTL_PEERS?
    throw new Error('GOVERNATOR_MAJOR_URL is required') unless @GOVERNATOR_MAJOR_URL?
    throw new Error('GOVERNATOR_MINOR_URL is required') unless @GOVERNATOR_MINOR_URL?

    etcdManager = new EtcdManager {ETCDCTL_PEERS}
    @etcd = etcdManager.getEtcd()

  get: (callback) =>
    async.parallel {
      status: @_getStatus
      deployments: @_getGovernatorMajor
      servers: @_getVulcandBackend
    }, callback

  _getStatus: (callback) =>
    @_getEtcd "/#{@repository}/status", callback

  _getEtcd: (key, callback) =>
    debug 'getEtcd', key
    @etcd.get key, recursive: true, (error, keys) =>
      return callback null, {} if error?.errorCode == 100
      return callback error if error?
      return callback new Error(keys) unless _.isPlainObject(keys)

      @etcdParser = new EtcdParserModel key, keys
      @etcdParser.parse callback

  _getVulcandBackend: (callback) =>
    debug 'getVulcandBackend', @repository
    service = @repository.replace('/', '-')
    key = "/vulcand/backends/#{service}/servers"
    @etcd.get key, recursive: true, (error, keys) =>
      return callback null, {error: error.message} if error?
      return callback null, {error: keys} unless _.isPlainObject(keys)

      @etcdParser = new EtcdParserModel key, keys
      servers = {}
      @etcdParser.parse (error, data) =>
        return callback error if error?

        _.each _.keys(data), (key) =>
          node = JSON.parse data[key]
          servers[node.Id] = node.URL

        callback null, servers

  _getGovernatorMajor: (callback) =>
    options =
      uri: "/status"
      baseUrl: @GOVERNATOR_MAJOR_URL
      json: true

    request.get options, (error, response) =>
      return callback error if error?
      unless response.statusCode == 200
        host = 'unknown'
        try
          {host} = url.parse(uri)
        error = new Error("Expected to get a 200, got an #{response.statusCode}. host: #{host}")
        error.code = response.code
        return callback error

      deploys = _.pick response.body, (value, key) =>
        _.startsWith key, "governator:/#{@repository}:"

      callback null, deploys

module.exports = StatusModel
