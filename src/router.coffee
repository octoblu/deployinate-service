DeployinateController = require './deployinate-controller'

class Router
  constructor: ->
    @deployinateController = new DeployinateController

  route: (app) =>
    app.post '/deploy', @deployinateController.deploy
    app.post '/workers/deploy', @deployinateController.deployWorker
    app.post '/rollback/:namespace/:service', @deployinateController.rollback
    app.get '/status/:namespace/:service', @deployinateController.getStatus

module.exports = Router
