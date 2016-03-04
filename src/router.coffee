StatusController = require './status-controller'
SchedulesController = require './schedules-controller'
DeploymentsController = require './deployments-controller'

class Router
  constructor: (options) ->
    {GOVERNATOR_MAJOR_URL, GOVERNATOR_MINOR_URL} = options
    {ETCD_MAJOR_URI, ETCD_MINOR_URI} = options
    {TRAVIS_ORG_URL, TRAVIS_ORG_TOKEN} = options
    {TRAVIS_PRO_URL, TRAVIS_PRO_TOKEN} = options

    throw new Error('ETCD_MAJOR_URI is required') unless ETCD_MAJOR_URI?
    throw new Error('ETCD_MINOR_URI is required') unless ETCD_MINOR_URI?
    throw new Error('GOVERNATOR_MAJOR_URL is required') unless GOVERNATOR_MAJOR_URL?
    throw new Error('GOVERNATOR_MINOR_URL is required') unless GOVERNATOR_MINOR_URL?

    @deploymentsController = new DeploymentsController {
      GOVERNATOR_MAJOR_URL
      GOVERNATOR_MINOR_URL
      TRAVIS_ORG_URL
      TRAVIS_ORG_TOKEN
      TRAVIS_PRO_URL
      TRAVIS_PRO_TOKEN
      ETCDCTL_PEERS: ETCD_MAJOR_URI
    }

    @statusController = new StatusController {
      GOVERNATOR_MAJOR_URL
      GOVERNATOR_MINOR_URL
      ETCD_MAJOR_URI
      ETCD_MINOR_URI
    }

    @schedulesController = new SchedulesController {
      GOVERNATOR_MAJOR_URL
    }

  route: (app) =>
    app.post '/deployments', @deploymentsController.create
    app.get '/status/:namespace/:service', @statusController.show
    app.post '/schedules', @schedulesController.create

module.exports = Router
