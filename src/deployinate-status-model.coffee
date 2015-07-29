_       = require 'lodash'
url     = require 'url'
Etcd    = require 'node-etcd'
debug   = require('debug')('deployinate-service:deployinate-status-model')

class DeployinateStatusModel
  constructor: (@namespace, @service, dependencies={}) ->
    @EtcdParserModel = dependencies.EtcdParserModel ? require './etcd-parser-model'

  getPeers: (callback=->) =>
    debug 'getPeers', process.env.ECTDCTL_PEERS
    return unless process.env.ECTDCTL_PEERS?
    peers = process.env.ECTDCTL_PEERS.split ','
    _.map peers, (peer) =>
      parsedUrl = url.parse peer
      "#{parsedUrl.host}:#{parsedUrl.port}"

  getStatus: (callback=->) =>
    debug 'getStatus', @namespace, @service
    etcd = new Etcd @getPeers()
    debug 'getEtcd'
    key = "/#{@namespace}/#{@service}"
    etcd.get key, recursive: true, (error, keys) =>
      debug 'gotStatus', error, keys
      @etcdParser = new @EtcdParserModel key, keys
      @etcdParser.parse (error, data) =>
        callback error, data

module.exports = DeployinateStatusModel
