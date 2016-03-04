_            = require 'lodash'
debug        = require('debug')('deployinate-service:schedule-controller')

class SchedulesController
  constructor: (options, dependencies={}) ->
    {@ETCDCTL_PEERS} = options
    {@GOVERNATOR_MAJOR_URL} = options

    @ScheduleModel = dependencies.ScheduleModel || require './schedule-model'

  create: (req, res) =>
    {dockerUrl, etcdDir, deployAt} = req.body
    @schedule = new @ScheduleModel {
      etcdDir
      dockerUrl
      @GOVERNATOR_MAJOR_URL
    }
    @schedule.create {deployAt}, (error) ->
      return res.status(error.code ? 500).send(error.message) if error?
      return res.status(201).end()

module.exports = SchedulesController
