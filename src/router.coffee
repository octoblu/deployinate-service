DeployinateController = require './deployinate-controller'
DeploymentsController = require './deployments-controller'

class Router
  constructor: (options) ->
    {ETCDCTL_PEERS, GOVERNATOR_MINOR_URL} = options
    {TRAVIS_ORG_URL, TRAVIS_ORG_TOKEN} = options
    {TRAVIS_PRO_URL, TRAVIS_PRO_TOKEN} = options
    @deployinateController = new DeployinateController
    @deploymentsController = new DeploymentsController {
      GOVERNATOR_MINOR_URL
      ETCDCTL_PEERS
      TRAVIS_ORG_URL
      TRAVIS_ORG_TOKEN
      TRAVIS_PRO_URL
      TRAVIS_PRO_TOKEN
    }

  route: (app) =>
    app.post '/deployments', @deploymentsController.create
    app.post '/deploy', @deployinateController.deploy
    app.post '/workers/deploy', @deployinateController.deployWorker
    app.post '/rollback/:namespace/:service', @deployinateController.rollback
    app.get '/status/:namespace/:service', @deployinateController.getStatus

module.exports = Router
