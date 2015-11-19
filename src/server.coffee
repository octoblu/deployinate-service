morgan             = require 'morgan'
express            = require 'express'
cors               = require 'cors'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
meshbluAuth        = require 'express-meshblu-auth'
MeshbluConfig      = require 'meshblu-config'
debug              = require('debug')('deployinate-service:server')
Router             = require './router'

class Server
  constructor: ({@port}, {@meshbluConfig}={})->
    @meshbluConfig ?= new MeshbluConfig().toJSON()

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use morgan('dev', immediate: false)
    app.use cors()
    app.use errorHandler()
    app.use meshbluHealthcheck()
    app.use meshbluAuth @meshbluConfig
    app.use bodyParser.urlencoded limit: '50mb', extended : true
    app.use bodyParser.json limit : '50mb'

    app.options '*', cors()

    router = new Router
    router.route app

    @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

module.exports = Server
