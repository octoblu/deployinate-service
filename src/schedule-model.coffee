_       = require 'lodash'
async   = require 'async'
{exec}  = require 'child_process'
request = require 'request'
url   = require 'url'
EtcdManager = require './etcd-manager'
TravisStatusModel = require './travis-status-model'
debug   = require('debug')('deployinate-service:deployinate-model')

class ScheduleModel
  constructor: (options) ->
    {@etcdDir, @dockerUrl} = options
    {@GOVERNATOR_MAJOR_URL} = options
    throw new Error('etcdDir is required') unless @etcdDir?
    throw new Error('dockerUrl is required') unless @dockerUrl?
    throw new Error('GOVERNATOR_MAJOR_URL is required') unless @GOVERNATOR_MAJOR_URL?

  _unprocessableError: (message) =>
    error = new Error message
    error.code = 422
    return error

  create: ({deployAt}, callback) =>
    return callback @_unprocessableError("invalid etcdDir: #{@etcdDir}") unless @etcdDir?
    return callback @_unprocessableError("invalid dockerUrl: #{@dockerUrl}") unless @dockerUrl?

    @_postGovernatorMajor {deployAt}, callback

  _postGovernatorMajor: ({deployAt}, callback) =>
    options =
      uri: '/schedules'
      baseUrl: @GOVERNATOR_MAJOR_URL
      json:
        etcdDir: @etcdDir
        dockerUrl: @dockerUrl
        deployAt: deployAt

    request.post options, (error, response) =>
      return callback error if error?
      unless response.statusCode == 201
        host = 'unknown'
        try
          {host} = url.parse(uri)
        error = new Error("Expected to get a 201, got an #{response.statusCode}. host: #{host}")
        error.code = response.code
        return callback error
      callback()

module.exports = ScheduleModel
