_       = require 'lodash'
{exec} = require 'child_process'
request = require 'request'
debug   = require('debug')('deployinate-service:deployinate-model')

class DeployinateModel
  constructor: (@repository, @docker_url, @tag, dependencies={}) ->
    debug '.new', @repository, @docker_url, @tag
    @repositoryDasherized = @repository?.replace '/', '-'

  deploy: (callback=->) =>
    @_getActiveAndNewColor (error, activeColor, newColor) =>
      @_setKey "#{@repository}/#{newColor}/docker_url", "#{@docker_url}:#{@tag}", =>
        @_getKey "#{@repository}/#{newColor}/count", (error, count) =>
          _.times count, (x) =>
            @_destroyService "#{@repositoryDasherized}-#{newColor}@#{x}", (error) =>
              @_startService "#{@repositoryDasherized}-#{newColor}@#{x}", (error) =>
                callback error

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
    exec "fleetctl destroy #{service}", (error, stdout, stderr) =>
      debug 'destroyService error:', error.message if error?
      debug 'destroyService stdout:', stdout if stdout?
      debug 'destroyService stderr:', stderr if stderr?
      callback error

  _startService: (service, callback=->) =>
    exec "fleetctl start #{service}", (error, stdout, stderr) =>
      debug 'startService error:', error.message if error?
      debug 'startService stdout:', stdout if stdout?
      debug 'startService stderr:', stderr if stderr?
      callback error



module.exports = DeployinateModel
