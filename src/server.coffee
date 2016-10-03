morgan             = require 'morgan'
express            = require 'express'
cors               = require 'cors'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
meshbluAuthDevice  = require 'express-meshblu-auth-device'
packageVersion     = require 'express-package-version'
Router             = require './router'

class Server
  constructor: (options)->
    {@port, @meshbluConfig} = options
    {@GOVERNATOR_MAJOR_URL, @GOVERNATOR_MINOR_URL, @GOVERNATOR_SWARM_URL} = options
    {@ETCD_MAJOR_URI, @ETCD_MINOR_URI} = options
    {@TRAVIS_ORG_TOKEN, @TRAVIS_ORG_URL} = options
    {@TRAVIS_PRO_URL, @TRAVIS_PRO_TOKEN} = options
    {@QUAY_URL, @QUAY_TOKEN} = options
    throw new Error('ETCD_MAJOR_URI is required') unless @ETCD_MAJOR_URI?
    throw new Error('ETCD_MINOR_URI is required') unless @ETCD_MINOR_URI?
    throw new Error('GOVERNATOR_MAJOR_URL is required') unless @GOVERNATOR_MAJOR_URL?
    throw new Error('GOVERNATOR_MINOR_URL is required') unless @GOVERNATOR_MINOR_URL?
    throw new Error('GOVERNATOR_SWARM_URL is required') unless @GOVERNATOR_SWARM_URL?
    throw new Error('TRAVIS_PRO_URL is required') unless @TRAVIS_PRO_URL?
    throw new Error('TRAVIS_ORG_URL is required') unless @TRAVIS_ORG_URL?
    throw new Error('TRAVIS_PRO_TOKEN is required') unless @TRAVIS_PRO_TOKEN?
    throw new Error('TRAVIS_ORG_TOKEN is required') unless @TRAVIS_ORG_TOKEN?
    throw new Error('QUAY_URL is required') unless @QUAY_URL?
    throw new Error('QUAY_TOKEN is required') unless @QUAY_TOKEN?
    throw new Error('UUID must be provided from meshbluConfig') unless @meshbluConfig?.uuid?

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use meshbluHealthcheck()
    app.use packageVersion()
    app.use morgan('dev', immediate: false)
    app.use cors()
    app.use errorHandler()
    app.use meshbluAuthDevice @meshbluConfig
    app.use bodyParser.urlencoded limit: '50mb', extended : true
    app.use bodyParser.json limit : '50mb'

    app.options '*', cors()

    router = new Router {
      @ETCD_MAJOR_URI
      @ETCD_MINOR_URI
      @GOVERNATOR_MAJOR_URL
      @GOVERNATOR_MINOR_URL
      @GOVERNATOR_SWARM_URL
      @TRAVIS_PRO_URL
      @TRAVIS_ORG_URL
      @TRAVIS_PRO_TOKEN
      @TRAVIS_ORG_TOKEN
      @QUAY_URL
      @QUAY_TOKEN
    }
    router.route app

    @server = app.listen @port, callback

  close: (callback) =>
    @server.close callback

module.exports = Server
