request = require 'request'
shmock  = require 'shmock'
url     = require 'url'
Server = require '../../src/server'

describe 'GET /status/foo/bar', ->
  beforeEach (done) ->
    @meshbluServer = shmock()
    meshbluAddress = @meshbluServer.address()

    @governatorMajor = shmock()
    @governatorMinor = shmock()

    GOVERNATOR_MAJOR_URL = url.format
      protocol: 'http'
      hostname: 'localhost'
      port: @governatorMajor.address().port
      auth: 'guv-uuid:guv-token'

    GOVERNATOR_MINOR_URL = url.format
      protocol: 'http'
      hostname: 'localhost'
      port: @governatorMinor.address().port
      auth: 'guv-uuid:guv-token'

    @etcd = shmock()
    ETCDCTL_PEERS = url.format protocol: 'http', hostname: 'localhost', port: @etcd.address().port

    meshbluConfig =
      protocol: 'http'
      server: 'localhost'
      port: meshbluAddress.port
      uuid: 'deploy-uuid'

    @sut = new Server {
      ETCDCTL_PEERS
      GOVERNATOR_MAJOR_URL
      GOVERNATOR_MINOR_URL
      TRAVIS_ORG_URL: 'nothing'
      TRAVIS_ORG_TOKEN: 'nothing'
      TRAVIS_PRO_URL: 'nothing'
      TRAVIS_PRO_TOKEN: 'nothing'
      meshbluConfig
    }
    @sut.run done

  afterEach (done) ->
    @sut.close done

  afterEach (done) ->
    @etcd.close done

  afterEach (done) ->
    @governatorMinor.close done

  afterEach (done) ->
    @governatorMajor.close done

  afterEach (done) ->
    @meshbluServer.close done

  beforeEach ->
    {port} = @sut.address()
    @baseUrl = url.format protocol: 'http', hostname: 'localhost', port: port

    deployAuth = new Buffer('deploy-uuid:deploy-token').toString 'base64'
    guvAuth = new Buffer('guv-uuid:guv-token').toString 'base64'

    @meshbluHandler = @meshbluServer
      .get '/v2/whoami'
      .set 'Authorization', "Basic #{deployAuth}"
      .reply 200, uuid: 'governator-uuid'

    @majorHandler = @governatorMajor
      .get '/status/foo/bar'
      .set 'Authorization', "Basic #{guvAuth}"
      .reply 200, [{branch: 'v1.0.2', result: 0}]

    @minorHandler = @governatorMinor
      .get '/status/foo/bar'
      .set 'Authorization', "Basic #{guvAuth}"
      .reply 200, [{branch: 'v1.0.2', result: 0}]

    statusNode =
      node:
        key: '/foo/bar/status'
        dir: true
        nodes: [
          key: '/foo/bar/status/travis'
          value: 'build successful: v1.0.0'
        ]

    envNode =
      node:
        key: '/foo/bar/env'
        dir: true
        nodes: [
          key: '/foo/bar/env/VAR'
          value: 'VALUE'
        ]

    @etcdStatusHandler = @etcd
      .get '/v2/keys/foo/bar/status'
      .reply 200, statusNode

    @etcdEnvHandler = @etcd
      .get '/v2/keys/foo/bar/env'
      .reply 200, envNode

  beforeEach (done) ->
    options =
      uri: '/status/foo/bar'
      baseUrl: @baseUrl
      auth: {username: 'deploy-uuid', password: 'deploy-token'}

    request.get options, (error, @response, @body) =>
      return done error if error?
      done()

  it 'should return a 200', ->
    expect(@response.statusCode).to.equal 200, JSON.stringify(@body)

  it 'should return a status', ->
    expectedResponse =
      status:
        travis: 'build successful: v1.0.0'
      env:
        VAR: 'VALUE'

    expect(JSON.parse @response.body).to.deep.equal expectedResponse

  it 'should call the handlers', ->
    expect(@meshbluHandler.isDone).to.be.true
    expect(@etcdStatusHandler.isDone).to.be.true
    expect(@etcdEnvHandler.isDone).to.be.true
    expect(@majorHandler.isDone).to.be.true
    expect(@minorHandler.isDone).to.be.true
