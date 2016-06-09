request       = require 'request'
enableDestroy = require 'server-destroy'
shmock        = require 'shmock'
url           = require 'url'

Server = require '../../src/server'

describe 'POST /schedules', ->
  beforeEach (done) ->
    @meshbluServer = shmock()
    enableDestroy @meshbluServer
    meshbluAddress = @meshbluServer.address()

    @governatorMajor = shmock()

    GOVERNATOR_MAJOR_URL = url.format
      protocol: 'http'
      hostname: 'localhost'
      port: @governatorMajor.address().port
      auth: 'guv-uuid:guv-token'

    meshbluConfig =
      protocol: 'http'
      server: 'localhost'
      port: meshbluAddress.port
      uuid: 'deploy-uuid'

    @sut = new Server {
      ETCD_MAJOR_URI: 'nothing'
      ETCD_MINOR_URI: 'nothing'
      GOVERNATOR_MAJOR_URL
      GOVERNATOR_MINOR_URL: 'nothing'
      TRAVIS_ORG_URL: 'nothing'
      TRAVIS_ORG_TOKEN: 'nothing'
      TRAVIS_PRO_URL: 'nothing'
      TRAVIS_PRO_TOKEN: 'nothing'
      QUAY_URL: 'nothing'
      QUAY_TOKEN: 'nothing'
      meshbluConfig
    }
    @sut.run done

  afterEach (done) ->
    @sut.close done

  afterEach (done) ->
    @governatorMajor.close done

  afterEach (done) ->
    @meshbluServer.destroy done

  beforeEach ->
    {port} = @sut.address()
    @baseUrl = url.format protocol: 'http', hostname: 'localhost', port: port

    deployAuth = new Buffer('deploy-uuid:deploy-token').toString 'base64'
    guvAuth = new Buffer('guv-uuid:guv-token').toString 'base64'

    @meshbluHandler = @meshbluServer
      .post '/authenticate'
      .set 'Authorization', "Basic #{deployAuth}"
      .reply 200, uuid: 'governator-uuid'

    @majorHandler = @governatorMajor
      .post '/schedules'
      .set 'Authorization', "Basic #{guvAuth}"
      .send {etcdDir: '/octoblu/some-service', dockerUrl: 'quay.io/octoblu/some-service:v1.0.2', deployAt: 151235995}
      .reply 201, {}

  beforeEach (done) ->
    options =
      uri: '/schedules'
      baseUrl: @baseUrl
      auth: {username: 'deploy-uuid', password: 'deploy-token'}
      json:
        etcdDir: '/octoblu/some-service'
        dockerUrl: 'quay.io/octoblu/some-service:v1.0.2'
        deployAt: 151235995

    request.post options, (error, @response, @body) =>
      return done error if error?
      done()

  it 'should return a 201', ->
    expect(@response.statusCode).to.equal 201, JSON.stringify(@body)

  it 'should call the handlers', ->
    expect(@meshbluHandler.isDone).to.be.true
    expect(@majorHandler.isDone).to.be.true
