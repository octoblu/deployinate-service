_                = require 'lodash'
url              = require 'url'
async            = require 'async'
EtcdManager      = require './etcd-manager'
EtcdParserModel = require './etcd-parser-model'
debug   = require('debug')('deployinate-service:deployinate-status-model')

class DeployinateStatusModel
  constructor: ({@repository, ETCDCTL_PEERS}) ->
    etcdManager = new EtcdManager {ETCDCTL_PEERS}
    @etcd = etcdManager.getEtcd()

  getStatus: (callback=->) =>
    async.parallel [
      @getService
      @getVulcandFrontend
      @getVulcandBackendBlue
      @getVulcandBackendGreen
    ], (error, results) =>
      return callback error if error?
      [service, frontend, blue, green] = results

      data =
        service: service
        frontend: frontend
        "backend-blue": blue
        "backend-green": green

      callback null, data

  getService: (callback=->) =>
    debug 'getService', @repository
    key = "/#{@repository}"
    @etcd.get key, recursive: true, (error, keys) =>
      return callback null, {error: error.message} if error?
      return callback null, {error: keys} unless _.isPlainObject(keys)

      @etcdParser = new EtcdParserModel key, keys
      @etcdParser.parse (error, data) =>
        callback error, data

  getVulcandFrontend: (callback=->) =>
    debug 'getVulcandFrontend', @repository
    service = @repository.replace('/', '-')
    key = "/vulcand/frontends/#{service}"
    @etcd.get key, recursive: true, (error, keys) =>
      return callback null, {error: error.message} if error?
      return callback null, {error: keys} unless _.isPlainObject(keys)

      @etcdParser = new EtcdParserModel key, keys
      @etcdParser.parse (error, data) =>
        return callback error if error?

        try
          data = JSON.parse(data?.frontend)
        catch

        callback null, data

  getVulcandBackendBlue: (callback=->) =>
    @getVulcandBackend 'blue', callback

  getVulcandBackendGreen: (callback=->) =>
    @getVulcandBackend 'green', callback

  getVulcandBackend: (color, callback=->) =>
    debug 'getVulcandBackend', color, @repository
    service = @repository.replace('/', '-')
    key = "/vulcand/backends/#{service}-#{color}"
    @etcd.get key, recursive: true, (error, keys) =>
      return callback null, {error: error.message} if error?
      return callback null, {error: keys} unless _.isPlainObject(keys)

      @etcdParser = new EtcdParserModel key, keys
      @etcdParser.parse (error, data) =>
        return callback error if error?

        _.each _.keys(data), (key) =>
          try
            data[key] = JSON.parse data[key]
          catch

        callback null, data

module.exports = DeployinateStatusModel
