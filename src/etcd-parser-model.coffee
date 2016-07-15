_       = require 'lodash'

class EtcdParserModel
  constructor: (@key, @data, dependencies={}) ->

  parse: (callback=->) =>
    result = @_parse @data
    callback null, _.object _.compact result

  _parse: (data) =>
    _.flatten _.compact _.map data, (node) =>
      return @_parse node.nodes if node.nodes?
      return unless node.key?
      [[node.key.replace("#{@key}/",''), node.value]]

module.exports = EtcdParserModel
