_       = require 'lodash'
async   = require 'async'
{exec}  = require 'child_process'
request = require 'request'
debug   = require('debug')('deployinate-service:deployinate-model')

class DeployinateModel
  constructor: (@repository, @docker_url, @tag, dependencies={}) ->
    debug '.new', @repository, @docker_url, @tag
    @repositoryDasherized = @repository?.replace '/', '-'

  deploy: (callback=->) =>
    return callback new Error("invalid repository: #{@repository}") unless @repository?
    return callback new Error("invalid docker_url: #{@docker_url}") unless @docker_url?
    return callback new Error("invalid tag: #{@tag}") unless @tag?
    @_getActiveAndNewColor (error, activeColor, newColor) =>
      return callback error if error?
      @_setKey "#{@repository}/#{newColor}/docker_url", "#{@docker_url}:#{@tag}", =>
        return callback error if error?
        @_deployAll newColor, callback

  _deployAll: (newColor, callback=->) =>
    @_getKey "#{@repository}/count", (error, count) =>
      return callback error if error?
      async.times count, (x, next) =>
        serviceName = "#{@repositoryDasherized}-#{newColor}@#{x+1}"
        registerServiceName = "#{@repositoryDasherized}-#{newColor}-register@#{x+1}"
        healthcheckServiceName = "#{@repositoryDasherized}-#{newColor}-healthcheck"

        # order is important, the service must run before the register service
        # or fleetctl start hangs
        async.series [
          (callback) => @_stopAndDestroyService registerServiceName, callback
          (callback) => @_stopAndDestroyService serviceName, callback
          (callback) => @_startService serviceName, callback
          (callback) => @_startService registerServiceName, callback
        ] , (error) =>
          return callback error if error?
          @_startService healthcheckServiceName, callback

  _stopAndDestroyService: (serviceName, callback=->) =>
    debug '_stopAndDestroyService', serviceName
    @_stopService serviceName, (error) =>
      return callback error if error?
      @_destroyService serviceName, (error) =>
        return callback error if error?
        callback()

  _getKey: (key, callback=->) =>
    debug 'getKey', key
    request.get "#{process.env.FLEETCTL_ENDPOINT}/v2/keys/#{key}", json: true, (error, body, response) =>
      return callback error if error?
      callback null, response?.node?.value

  _setKey: (key, value, callback=->) =>
    debug 'setKey', key, value
    request.put "#{process.env.FLEETCTL_ENDPOINT}/v2/keys/#{key}", form: {value: value}, (error, body, response) =>
      return callback error if error?
      callback null, response?.node?.value

  _getActiveAndNewColor: (callback=->) =>
    @_getKey "#{@repository}/active", (error, activeColor) =>
      return callback error if error?
      if activeColor == 'green'
        newColor = 'blue'
      else
        newColor = 'green'

      callback null, activeColor, newColor

  _destroyService: (service, callback=->) =>
    debug '_destroyService', service
    exec "fleetctl destroy #{service}", (error, stdout, stderr) =>
      debug 'destroyService error:', error.message if error?
      debug 'destroyService stdout:', stdout if stdout?
      debug 'destroyService stderr:', stderr if stderr?
      callback error

  _stopService: (service, callback=->) =>
    debug '_stopService', service
    exec "fleetctl stop #{service}", (error, stdout, stderr) =>
      debug 'stopService error:', error.message if error?
      debug 'stopService stdout:', stdout if stdout?
      debug 'stopService stderr:', stderr if stderr?
      return callback() if error?.killed == false
      callback error

  _startService: (service, callback=->) =>
    debug '_startService', service
    exec "fleetctl start #{service}", (error, stdout, stderr) =>
      debug 'startService error:', error.message if error?
      debug 'startService stdout:', stdout if stdout?
      debug 'startService stderr:', stderr if stderr?
      callback error

module.exports = DeployinateModel
