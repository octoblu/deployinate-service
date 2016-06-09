CancellationsController = require './cancellations-controller'
DeploymentsController   = require './deployments-controller'
SchedulesController     = require './schedules-controller'
StatusController        = require './status-controller'

class Router
  constructor: (options) ->
    {GOVERNATOR_MAJOR_URL, GOVERNATOR_MINOR_URL} = options
    {ETCD_MAJOR_URI, ETCD_MINOR_URI} = options
    {TRAVIS_ORG_URL, TRAVIS_ORG_TOKEN} = options
    {TRAVIS_PRO_URL, TRAVIS_PRO_TOKEN} = options
    {QUAY_URL, QUAY_TOKEN} = options

    throw new Error('ETCD_MAJOR_URI is required') unless ETCD_MAJOR_URI?
    throw new Error('ETCD_MINOR_URI is required') unless ETCD_MINOR_URI?
    throw new Error('GOVERNATOR_MAJOR_URL is required') unless GOVERNATOR_MAJOR_URL?
    throw new Error('GOVERNATOR_MINOR_URL is required') unless GOVERNATOR_MINOR_URL?
    throw new Error('TRAVIS_ORG_URL is required') unless TRAVIS_ORG_URL?
    throw new Error('TRAVIS_ORG_TOKEN is required') unless TRAVIS_ORG_TOKEN?
    throw new Error('TRAVIS_PRO_URL is required') unless TRAVIS_PRO_URL?
    throw new Error('TRAVIS_PRO_TOKEN is required') unless TRAVIS_PRO_TOKEN?
    throw new Error('QUAY_URL is required') unless QUAY_URL?
    throw new Error('QUAY_TOKEN is required') unless QUAY_TOKEN?

    @cancellationsController = new CancellationsController {
      GOVERNATOR_MAJOR_URL
      GOVERNATOR_MINOR_URL
      ETCDCTL_PEERS: ETCD_MAJOR_URI
    }

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
      QUAY_URL
      QUAY_TOKEN
    }

    @schedulesController = new SchedulesController {
      GOVERNATOR_MAJOR_URL
    }

  route: (app) =>
    app.post '/deployments', @deploymentsController.create
    app.post '/cancellations', @cancellationsController.create
    app.get '/status/:namespace/:service', @statusController.show
    app.post '/schedules', @schedulesController.create

module.exports = Router
