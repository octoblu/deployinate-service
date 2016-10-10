async   = require 'async'
request = require 'request'
url   = require 'url'

class CancellationModel
  constructor: (options) ->
    {@repository, @docker_url, @tag} = options
    {@ETCDCTL_PEERS} = options
    {@GOVERNATOR_MAJOR_URL, @GOVERNATOR_MINOR_URL} = options
    throw new Error('repository is required') unless @repository?
    throw new Error('docker_url is required') unless @docker_url?
    throw new Error('tag is required') unless @tag?
    throw new Error('ETCDCTL_PEERS is required') unless @ETCDCTL_PEERS?
    throw new Error('GOVERNATOR_MAJOR_URL is required') unless @GOVERNATOR_MAJOR_URL?
    throw new Error('GOVERNATOR_MINOR_URL is required') unless @GOVERNATOR_MINOR_URL?
    @repositoryDasherized = @repository?.replace '/', '-'

  _unprocessableError: (message) =>
    error = new Error message
    error.code = 422
    return error

  _preconditionError: (message) =>
    error = new Error message
    error.code = 412
    return error

  create: (callback) =>
    return callback @_unprocessableError("invalid repository: #{@repository}") unless @repository?
    return callback @_unprocessableError("invalid docker_url: #{@docker_url}") unless @docker_url?
    return callback @_unprocessableError("invalid tag: #{@tag}") unless @tag?

    async.series [
      @_postGovernatorMajor
      @_postGovernatorMinor
    ], callback

  _postGovernatorMinor: (callback) =>
    @_postGovernator uri: @GOVERNATOR_MINOR_URL, callback

  _postGovernatorMajor: (callback) =>
    @_postGovernator uri: @GOVERNATOR_MAJOR_URL, callback

  _postGovernator: ({uri}, callback) =>
    options =
      uri: '/cancellations'
      baseUrl: uri
      json:
        etcdDir: "/#{@repository}"
        dockerUrl: "#{@docker_url}:#{@tag}"

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

module.exports = CancellationModel
