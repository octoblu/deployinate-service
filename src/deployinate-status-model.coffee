_       = require 'lodash'
url     = require 'url'
EtcdManager = require './etcd-manager'

debug   = require('debug')('deployinate-service:deployinate-status-model')

class DeployinateStatusModel
  constructor: (@repository, dependencies={}) ->
    @EtcdParserModel = dependencies.EtcdParserModel ? require './etcd-parser-model'

  getPeers: (callback=->) =>
    debug 'getPeers', process.env.ETCDCTL_PEERS
    return unless process.env.ETCDCTL_PEERS?
    peers = process.env.ETCDCTL_PEERS.split ','
    _.map peers, (peer) =>
      parsedUrl = url.parse peer
      parsedUrl.host

  getStatus: (callback=->) =>
    debug 'getStatus', @repository
    etcdManager = new EtcdManager()
    etcd = etcdManager.getEtcd()
    key = "/#{@repository}"
    debug 'getEtcd', key, @getPeers()
    etcd.get key, recursive: true, (error, keys) =>
      return callback error if error?
      debug 'gotStatus', keys
      return callback new Error(keys) unless _.isPlainObject(keys)

      @etcdParser = new @EtcdParserModel key, keys
      @etcdParser.parse (error, data) =>
        callback error, data

module.exports = DeployinateStatusModel
