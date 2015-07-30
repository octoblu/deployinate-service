_       = require 'lodash'
url     = require 'url'
Etcd    = require 'node-etcd'
debug   = require('debug')('deployinate-service:etcd-manager')

class EctdManager
  constructor: (dependencies={}) ->

  getEtcd: =>
    new Etcd @_getPeers()

  _getPeers: (callback=->) =>
    debug 'getPeers', process.env.ETCDCTL_PEERS
    return unless process.env.ETCDCTL_PEERS?
    peers = process.env.ETCDCTL_PEERS.split ','
    _.map peers, (peer) =>
      parsedUrl = url.parse peer
      parsedUrl.host

module.exports = EctdManager
