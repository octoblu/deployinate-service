_       = require 'lodash'
async   = require 'async'
{exec}  = require 'child_process'
request = require 'request'
EtcdManager = require './etcd-manager'
DeployinateStatusModel = require './deployinate-status-model'
debug   = require('debug')('deployinate-service:deployinate-model')

class DeployinateModel
  constructor: (@repository, @docker_url, @tag, dependencies={}) ->
    debug '.new', @repository, @docker_url, @tag
    @repositoryDasherized = @repository?.replace '/', '-'

  deploy: (callback=->) =>
    return callback new Error("invalid repository: #{@repository}") unless @repository?
    return callback new Error("invalid docker_url: #{@docker_url}") unless @docker_url?
    return callback new Error("invalid tag: #{@tag}") unless @tag?

    @_getStatus (error, status) =>
      return callback error if error?
      @newColor = @_getNewColor status?.service?.active
      debug 'New Color', @newColor
      @_setKey "#{@repository}/#{@newColor}/docker_url", "#{@docker_url}:#{@tag}", =>
        return callback error if error?
        @_deployAll parseInt(status?.service?.count), callback

  _deployAll: (count, callback=->) =>
    debug '_deployAll', count
    @_restartServices count, (error, res) =>
      return callback error if error?

      healthcheckServiceName = "#{@repositoryDasherized}-#{@newColor}-healthcheck"
      @_stopService healthcheckServiceName, (error) =>
        return callback error if error?
        @_startService healthcheckServiceName, callback

  _getStatus: (callback=->) =>
    deployinateStatus = new DeployinateStatusModel @repository
    deployinateStatus.getStatus callback

  _restartServices: (count, callback=->) =>
    debug '_restartServices', count
    serviceName = "#{@repositoryDasherized}-#{@newColor}@{1..#{count}}"
    registerServiceName = "#{@repositoryDasherized}-#{@newColor}-register@{1..#{count}}"

    # order is important, the service must run before the register service
    # or fleetctl start hangs
    async.series [
      async.apply @_stopAndDestroyService, registerServiceName
      async.apply @_stopAndDestroyService, serviceName
      async.apply @_startService, serviceName
      async.apply @_startService, registerServiceName
    ], callback

  _stopAndDestroyService: (serviceName, callback=->) =>
    debug '_stopAndDestroyService', serviceName
    @_stopService serviceName, (error) =>
      return callback error if error?
      @_destroyService serviceName, (error) =>
        return callback error if error?
        callback()

  _setKey: (key, value, callback=->) =>
    debug 'setKey', key, value
    etcdManager = new EtcdManager()
    etcd = etcdManager.getEtcd()
    etcd.set key, value, callback

  _getNewColor: (activeColor, callback=->) =>
    return 'blue' if activeColor == 'green'
    'green'

  _destroyService: (service, callback=->) =>
    debug '_destroyService', service
    exec "/bin/bash -c 'fleetctl destroy #{service}'", (error, stdout, stderr) =>
      debug 'destroyService error:', error.message if error?
      debug 'destroyService stdout:', stdout if stdout?
      debug 'destroyService stderr:', stderr if stderr?
      callback error

  _stopService: (service, callback=->) =>
    debug '_stopService', service
    exec "/bin/bash -c 'fleetctl stop #{service}'", (error, stdout, stderr) =>
      debug 'stopService error:', error.message if error?
      debug 'stopService stdout:', stdout if stdout?
      debug 'stopService stderr:', stderr if stderr?
      return callback() if error?.killed == false
      callback error

  _startService: (service, callback=->) =>
    debug '_startService', service
    exec "/bin/bash -c 'fleetctl start #{service}'", (error, stdout, stderr) =>
      debug 'startService error:', error.message if error?
      debug 'startService stdout:', stdout if stdout?
      debug 'startService stderr:', stderr if stderr?
      callback error

module.exports = DeployinateModel
