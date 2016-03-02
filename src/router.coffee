StatusController = require './status-controller'
DeploymentsController = require './deployments-controller'

class Router
  constructor: (options) ->
    {ETCDCTL_PEERS} = options
    {GOVERNATOR_MAJOR_URL, GOVERNATOR_MINOR_URL} = options
    {TRAVIS_ORG_URL, TRAVIS_ORG_TOKEN} = options
    {TRAVIS_PRO_URL, TRAVIS_PRO_TOKEN} = options

    @deploymentsController = new DeploymentsController {
      GOVERNATOR_MAJOR_URL
      GOVERNATOR_MINOR_URL
      ETCDCTL_PEERS
      TRAVIS_ORG_URL
      TRAVIS_ORG_TOKEN
      TRAVIS_PRO_URL
      TRAVIS_PRO_TOKEN
    }

    @statusController = new StatusController {
      GOVERNATOR_MAJOR_URL
      GOVERNATOR_MINOR_URL
      ETCDCTL_PEERS
    }

  route: (app) =>
    app.post '/deployments', @deploymentsController.create
    app.get '/status/:namespace/:service', @statusController.show

module.exports = Router
