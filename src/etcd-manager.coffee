_       = require 'lodash'
url     = require 'url'
Etcd    = require 'node-etcd'
debug   = require('debug')('deployinate-service:etcd-manager')

class EctdManager
  constructor: ({@ETCDCTL_PEERS}) ->
    throw new Error('ETCDCTL_PEERS is required') unless @ETCDCTL_PEERS?

  getEtcd: =>
    new Etcd @_getPeers()

  _getPeers: (callback=->) =>
    debug 'getPeers', @ETCDCTL_PEERS
    return unless @ETCDCTL_PEERS?
    peers = @ETCDCTL_PEERS.split ','
    _.map peers, (peer) =>
      parsedUrl = url.parse peer
      parsedUrl.host

module.exports = EctdManager
