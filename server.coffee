cors = require 'cors'
morgan = require 'morgan'
express = require 'express'
bodyParser = require 'body-parser'
meshbluAuth = require 'express-meshblu-auth'
errorHandler = require 'errorhandler'
MeshbluAuthExpress = require 'express-meshblu-auth/src/meshblu-auth-express'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
DeployinateController = require './src/deployinate-controller'

PORT = process.env.DEPLOYINATE_SERVICE_PORT ? 80

app = express()
app.use cors()
app.use morgan('combined')
app.use errorHandler()
app.use meshbluHealthcheck()
app.use bodyParser.urlencoded limit: '50mb', extended : true
app.use bodyParser.json limit : '50mb'

meshbluConfig = new MeshbluConfig().toJSON()
app.use meshbluAuth meshbluConfig

app.options '*', cors()

deployinateController = new DeployinateController meshbluConfig

app.post '/deploy', deployinateController.deploy
app.post '/rollback', deployinateController.rollback

server = app.listen PORT, ->
  host = server.address().address
  port = server.address().port

  console.log "Server running on #{host}:#{port}"
