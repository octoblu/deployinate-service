request       = require 'request'
enableDestroy = require 'server-destroy'
shmock        = require 'shmock'
url           = require 'url'

Server = require '../../src/server'

describe 'POST /deployments', ->
  beforeEach (done) ->
    @meshbluServer = shmock()
    enableDestroy @meshbluServer
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
    ETCD_MAJOR_URI = url.format protocol: 'http', hostname: 'localhost', port: @etcd.address().port

    @travisOrg = shmock()
    TRAVIS_ORG_URL = url.format protocol: 'http', hostname: 'localhost', port: @travisOrg.address().port
    TRAVIS_ORG_TOKEN = 'travis-org-token'

    @travisPro = shmock()
    TRAVIS_PRO_URL = url.format protocol: 'http', hostname: 'localhost', port: @travisPro.address().port
    TRAVIS_PRO_TOKEN = 'travis-pro-token'

    meshbluConfig =
      protocol: 'http'
      server: 'localhost'
      port: meshbluAddress.port
      uuid: 'deploy-uuid'

    @sut = new Server {
      ETCD_MAJOR_URI
      ETCD_MINOR_URI: 'nothing'
      GOVERNATOR_MAJOR_URL
      GOVERNATOR_MINOR_URL
      TRAVIS_ORG_URL
      TRAVIS_ORG_TOKEN
      TRAVIS_PRO_URL
      TRAVIS_PRO_TOKEN
      QUAY_URL: 'nothing'
      QUAY_TOKEN: 'nothing'
      meshbluConfig
    }
    @sut.run done

  afterEach (done) ->
    @sut.close done

  afterEach (done) ->
    @travisPro.close done

  afterEach (done) ->
    @travisOrg.close done

  afterEach (done) ->
    @etcd.close done

  afterEach (done) ->
    @governatorMinor.close done

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

    @travisOrgHandler = @travisOrg
      .get '/repos/octoblu/some-service/builds'
      .set 'Authorization', 'token travis-org-token'
      .reply 200, [{branch: 'v1.0.2', result: 0}]

    @majorHandler = @governatorMajor
      .post '/deployments'
      .set 'Authorization', "Basic #{guvAuth}"
      .reply 201, [{branch: 'v1.0.2', result: 0}]

    @minorHandler = @governatorMinor
      .post '/deployments'
      .set 'Authorization', "Basic #{guvAuth}"
      .reply 201, [{branch: 'v1.0.2', result: 0}]

  beforeEach (done) ->
    options =
      uri: '/deployments'
      baseUrl: @baseUrl
      auth: {username: 'deploy-uuid', password: 'deploy-token'}
      json:
        repository: 'octoblu/some-service'
        docker_url: 'quay.io/octoblu/some-service'
        updated_tags: ['v1.0.2']

    request.post options, (error, @response, @body) =>
      return done error if error?
      done()

  it 'should return a 201', ->
    expect(@response.statusCode).to.equal 201, JSON.stringify(@body)

  it 'should call the handlers', ->
    expect(@meshbluHandler.isDone).to.be.true
    expect(@travisOrgHandler.isDone).to.be.true
    expect(@majorHandler.isDone).to.be.true
    expect(@minorHandler.isDone).to.be.true
