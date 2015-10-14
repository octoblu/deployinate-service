_       = require 'lodash'
url     = require 'url'
async   = require 'async'
{exec}  = require 'child_process'
EtcdManager = require './etcd-manager'
DeployinateStatusModel = require './deployinate-status-model'
debug   = require('debug')('deployinate-service:deployinate-status-model')

class DeployinateRollbackModel
  constructor: (@repository, dependencies={}) ->
    etcdManager = new EtcdManager()
    @etcd = etcdManager.getEtcd()
    @repositoryDasherized = @repository?.replace '/', '-'

  rollback: (callback=->) =>
    @_getStatus (error, status) =>
      activeColor = status?.service?.active
      @newColor = @_getNewColor activeColor
      healthcheckServiceName = "#{@repositoryDasherized}-#{@newColor}-healthcheck"

      async.series [
        async.apply @_setKey, "#{@repository}/current_step", 'begin rollback'
        async.apply @_setKey, "#{@repository}/target", @newColor
        async.apply @_setKey, "#{@repository}/#{@newColor}/deployed_at", new Date().toISOString()
        async.apply @_stopService, healthcheckServiceName
        async.apply @_startService, healthcheckServiceName
        async.apply @_setKey, "#{@repository}/current_step", 'end rollback'
      ], callback

  _getNewColor: (activeColor, callback=->) =>
    return 'blue' if activeColor == 'green'
    'green'

  _getStatus: (callback=->) =>
    deployinateStatus = new DeployinateStatusModel @repository
    deployinateStatus.getStatus callback

  _setKey: (key, value, callback=->) =>
    debug 'setKey', key, value
    etcdManager = new EtcdManager()
    etcd = etcdManager.getEtcd()
    etcd.set key, value, callback

  _stopService: (service, callback=->) =>
    debug '_stopService', service
    @_setKey "#{@repository}/current_step", "stopService", (error) =>
      return callback error if error?
      exec "/bin/bash -c 'fleetctl stop #{service}'", (error, stdout, stderr) =>
        debug 'stopService error:', error.message if error?
        debug 'stopService stdout:', stdout if stdout?
        debug 'stopService stderr:', stderr if stderr?
        return callback() if error?.killed == false
        callback error

  _startService: (service, callback=->) =>
    debug '_startService', service
    @_setKey "#{@repository}/current_step", "startService", (error) =>
      return callback error if error?
      exec "/bin/bash -c 'fleetctl start #{service}'", (error, stdout, stderr) =>
        debug 'startService error:', error.message if error?
        debug 'startService stdout:', stdout if stdout?
        debug 'startService stderr:', stderr if stderr?
        callback error

module.exports = DeployinateRollbackModel
