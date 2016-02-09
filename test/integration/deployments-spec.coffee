request = require 'request'
shmock  = require 'shmock'
url     = require 'url'
Server = require '../../src/server'

describe 'POST /deployments', ->
  beforeEach (done) ->
    @meshbluServer = shmock()
    meshbluAddress = @meshbluServer.address()

    @governatorMinor = shmock()
    GOVERNATOR_MINOR_URL = url.format
      protocol: 'http'
      hostname: 'localhost'
      port: @governatorMinor.address().port
      pathname: '/deployments'
      auth: 'guv-uuid:guv-token'

    @etcd = shmock()
    ETCDCTL_PEERS = url.format protocol: 'http', hostname: 'localhost', port: @etcd.address().port

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
      ETCDCTL_PEERS
      GOVERNATOR_MINOR_URL
      TRAVIS_ORG_URL
      TRAVIS_ORG_TOKEN
      TRAVIS_PRO_URL
      TRAVIS_PRO_TOKEN
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
    @meshbluServer.close done

  beforeEach ->
    {port} = @sut.address()
    @baseUrl = url.format protocol: 'http', hostname: 'localhost', port: port

    deployAuth = new Buffer('deploy-uuid:deploy-token').toString 'base64'
    guvAuth = new Buffer('guv-uuid:guv-token').toString 'base64'

    @meshbluServer
      .get '/v2/whoami'
      .set 'Authorization', "Basic #{deployAuth}"
      .reply 200, uuid: 'governator-uuid'

    @travisOrg
      .get '/repos/octoblu/some-service/builds'
      .set 'Authorization', 'token travis-org-token'
      .reply 200, [{branch: 'v1.0.2', result: 0}]

    @governatorMinor
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
