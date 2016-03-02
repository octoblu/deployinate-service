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
    async.parallel [
      @_getStatus
      @_getEnv
      @_getGovernatorMinor
      @_getGovernatorMajor
    ], (error, results) =>
      return callback error if error?
      [status, env] = results

      data =
        status: status
        env: env
        # minor: minorStatus
        # major: majorStatus

      callback null, data

  _getStatus: (callback) =>
    @_getEtcd "/#{@repository}/status", callback

  _getEnv: (callback) =>
    @_getEtcd "/#{@repository}/env", callback

  _getEtcd: (key, callback) =>
    debug 'getEtcd', key
    @etcd.get key, recursive: true, (error, keys) =>
      return callback error if error?
      return callback new Error(keys) unless _.isPlainObject(keys)

      @etcdParser = new EtcdParserModel key, keys
      @etcdParser.parse (error, data) =>
        callback error, data

  # getVulcandFrontend: (callback) =>
  #   debug 'getVulcandFrontend', @repository
  #   service = @repository.replace('/', '-')
  #   key = "/vulcand/frontends/#{service}"
  #   @etcd.get key, recursive: true, (error, keys) =>
  #     return callback null, {error: error.message} if error?
  #     return callback null, {error: keys} unless _.isPlainObject(keys)
  #
  #     @etcdParser = new EtcdParserModel key, keys
  #     @etcdParser.parse (error, data) =>
  #       return callback error if error?
  #
  #       try
  #         data = JSON.parse(data?.frontend)
  #       catch
  #
  #       callback null, data
  #
  # getVulcandBackendBlue: (callback) =>
  #   @getVulcandBackend 'blue', callback
  #
  # getVulcandBackendGreen: (callback) =>
  #   @getVulcandBackend 'green', callback
  #
  # getVulcandBackend: (color, callback) =>
  #   debug 'getVulcandBackend', color, @repository
  #   service = @repository.replace('/', '-')
  #   key = "/vulcand/backends/#{service}-#{color}"
  #   @etcd.get key, recursive: true, (error, keys) =>
  #     return callback null, {error: error.message} if error?
  #     return callback null, {error: keys} unless _.isPlainObject(keys)
  #
  #     @etcdParser = new EtcdParserModel key, keys
  #     @etcdParser.parse (error, data) =>
  #       return callback error if error?
  #
  #       _.each _.keys(data), (key) =>
  #         try
  #           data[key] = JSON.parse data[key]
  #         catch
  #
  #       callback null, data

  _getGovernatorMinor: (callback) =>
    @_getGovernator uri: @GOVERNATOR_MINOR_URL, callback

  _getGovernatorMajor: (callback) =>
    @_getGovernator uri: @GOVERNATOR_MAJOR_URL, callback

  _getGovernator: ({uri}, callback) =>
    options =
      uri: "/status/#{@repository}"
      baseUrl: uri
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
      callback null, response.body

module.exports = StatusModel
