morgan             = require 'morgan'
express            = require 'express'
cors               = require 'cors'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
meshbluAuth        = require 'express-meshblu-auth'
debug              = require('debug')('deployinate-service:server')
Router             = require './router'

class Server
  constructor: (options)->
    {@port, @GOVERNATOR_MINOR_URL, @ETCDCTL_PEERS, @meshbluConfig} = options
    {@TRAVIS_ORG_TOKEN, @TRAVIS_ORG_URL} = options
    {@TRAVIS_PRO_URL, @TRAVIS_PRO_TOKEN} = options
    throw new Error('ETCDCTL_PEERS is required') unless @ETCDCTL_PEERS?
    throw new Error('GOVERNATOR_MINOR_URL is required') unless @GOVERNATOR_MINOR_URL?
    throw new Error('TRAVIS_PRO_URL is required') unless @TRAVIS_PRO_URL?
    throw new Error('TRAVIS_ORG_URL is required') unless @TRAVIS_ORG_URL?
    throw new Error('TRAVIS_PRO_TOKEN is required') unless @TRAVIS_PRO_TOKEN?
    throw new Error('TRAVIS_ORG_TOKEN is required') unless @TRAVIS_ORG_TOKEN?
    throw new Error('UUID must be provided from meshbluConfig') unless @meshbluConfig?.uuid?

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use meshbluHealthcheck()
    app.use morgan('dev', immediate: false)
    app.use cors()
    app.use errorHandler()
    app.use meshbluAuth @meshbluConfig
    app.use bodyParser.urlencoded limit: '50mb', extended : true
    app.use bodyParser.json limit : '50mb'

    app.options '*', cors()

    router = new Router {
      @ETCDCTL_PEERS
      @GOVERNATOR_MINOR_URL
      @TRAVIS_PRO_URL
      @TRAVIS_ORG_URL
      @TRAVIS_PRO_TOKEN
      @TRAVIS_ORG_TOKEN
    }
    router.route app

    @server = app.listen @port, callback

  close: (callback) =>
    @server.close callback

module.exports = Server
