_       = require 'lodash'
debug   = require('debug')('deployinate-service:deployinate-model')

class DeployinateModel
  constructor: (@repository, @docker_url, @tag, dependencies={}) ->
    @repositoryDasherized = _.replace @repository, '/', '-'

  deploy: (callback=->) =>
    @getActiveAndNewColor (error, activeColor, newColor) =>
      exec "fleetctl destroy #{@repositoryDasherized}-#{newColor}.service", (error, stdout, stderr) =>
        console.error('exec error:', error.message) if error?
        console.log stdout if stdout?
        console.error stderr if stderr?
        callback error

  rollback: (callback=->) =>
    exec "fleetctl start global-flow-runner-update.service", (error, stdout, stderr) =>
      console.error('exec error:', error.message) if error?
      console.log stdout if stdout?
      console.error stderr if stderr?
      callback error

  getKey: (key, callback=->) =>
    request.get "#{process.env.FLEETCTL_ENDPOINT}/v2/keys/@name", (error, body, response) =>

  getActiveAndNewColor: (callback=->) =>
    @getKey "#{@repository}/active", (error, activeColor) =>
      return callback error if error?
      if activeColor == 'green'
        newColor = 'blue'
      else
        newColor = 'green'

      callback null, activeColor, newColor

module.exports = DeployinateModel
