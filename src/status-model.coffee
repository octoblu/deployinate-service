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
    {@GOVERNATOR_MAJOR_URL, @GOVERNATOR_MINOR_URL} = options
    {@ETCD_MAJOR_URI, @ETCD_MINOR_URI} = options
    {@QUAY_URL, @QUAY_TOKEN} = options
    throw new Error('repository is required') unless @repository?
    throw new Error('ETCD_MAJOR_URI is required') unless @ETCD_MAJOR_URI?
    throw new Error('ETCD_MINOR_URI is required') unless @ETCD_MINOR_URI?
    throw new Error('GOVERNATOR_MAJOR_URL is required') unless @GOVERNATOR_MAJOR_URL?
    throw new Error('GOVERNATOR_MINOR_URL is required') unless @GOVERNATOR_MINOR_URL?
    throw new Error('QUAY_URL is required') unless @QUAY_URL?
    throw new Error('QUAY_TOKEN is required') unless @QUAY_TOKEN?

  get: (callback) =>
    async.parallel {
      majorVersion: @_getMajorVersion
      minorVersion: @_getMinorVersion
      status: @_getStatus
      deployments: @_getGovernatorMajor
      servers: @_getVulcandBackend
      quay: @_getQuayStatus
    }, callback

  _getStatus: (callback) =>
    @_getEtcd @ETCD_MAJOR_URI, "/#{@repository}/status", callback

  _getQuayStatus: (callback) =>
    options =
      uri: "/api/v1/repository/#{@repository}/build/"
      baseUrl: @QUAY_URL
      json: true
      headers:
        Authorization: "token #{@QUAY_TOKEN}"

    request.get options, (error, response) =>
      return callback error if error?
      unless response.statusCode == 200
        error = new Error("Expected to get a 200, got an #{response.statusCode}. host: #{@QUAY_URL}")
        error.code = response.code
        return callback error
      return callback null, {} if _.isEmpty response.body?.builds

      quayBuild = _.first response.body.builds
      build =
        tag: _.first quayBuild.tags
        phase: quayBuild.phase
        startedAt: quayBuild.started

      callback null, build

  _getMajorVersion: (callback) =>
    @_getEtcd @ETCD_MAJOR_URI, "/#{@repository}/docker_url", (error, data) =>
      return callback error if error?
      callback null, _.first _.values data

  _getMinorVersion: (callback) =>
    @_getEtcd @ETCD_MINOR_URI, "/#{@repository}/docker_url", (error, data) =>
      return callback error if error?
      callback null, _.first _.values data

  _getEtcd: (uri, key, callback) =>
    debug 'getEtcd', uri, key
    etcdManager = new EtcdManager ETCDCTL_PEERS: uri
    etcd = etcdManager.getEtcd()
    etcd.get key, recursive: true, (error, keys) =>
      return callback null, {} if error?.errorCode == 100
      return callback error if error?
      return callback new Error(keys) unless _.isPlainObject(keys)

      etcdParser = new EtcdParserModel key, keys
      etcdParser.parse callback

  _getVulcandBackend: (callback) =>
    debug 'getVulcandBackend', @repository
    service = @repository.replace('/', '-')
    key = "/vulcand/backends/#{service}/servers"
    etcdManager = new EtcdManager ETCDCTL_PEERS: @ETCD_MAJOR_URI
    etcd = etcdManager.getEtcd()
    etcd.get key, recursive: true, (error, keys) =>
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
          {host} = url.parse(@GOVERNATOR_MAJOR_URL)
        error = new Error("Expected to get a 200, got an #{response.statusCode}. host: #{host}")
        error.code = response.code
        return callback error

      deploys = _.pick response.body, (value, key) =>
        _.startsWith key, "governator:/#{@repository}:"

      callback null, deploys

module.exports = StatusModel
