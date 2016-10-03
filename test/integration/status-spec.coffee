{afterEach, beforeEach, describe, it} = global
{expect} = require 'chai'

request       = require 'request'
enableDestroy = require 'server-destroy'
shmock        = require 'shmock'
url           = require 'url'

Server = require '../../src/server'

describe 'GET /status/foo/bar', ->
  beforeEach (done) ->
    @meshbluServer = shmock()
    enableDestroy @meshbluServer
    meshbluAddress = @meshbluServer.address()

    @governatorMajor = shmock()
    @governatorMinor = shmock()
    @governatorSwarm = shmock()

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

    GOVERNATOR_SWARM_URL = url.format
      protocol: 'http'
      hostname: 'localhost'
      port: @governatorSwarm.address().port
      auth: 'guv-uuid:guv-token'

    @etcdMajor = shmock()
    @etcdMinor = shmock()
    ETCD_MAJOR_URI = url.format protocol: 'http', hostname: 'localhost', port: @etcdMajor.address().port
    ETCD_MINOR_URI = url.format protocol: 'http', hostname: 'localhost', port: @etcdMinor.address().port

    @quay = shmock()
    QUAY_URL = url.format
      protocol: 'http'
      hostname: 'localhost'
      port: @quay.address().port

    meshbluConfig =
      protocol: 'http'
      server: 'localhost'
      port: meshbluAddress.port
      uuid: 'deploy-uuid'

    @sut = new Server {
      ETCD_MAJOR_URI
      ETCD_MINOR_URI
      GOVERNATOR_MAJOR_URL
      GOVERNATOR_MINOR_URL
      GOVERNATOR_SWARM_URL
      TRAVIS_ORG_URL: 'nothing'
      TRAVIS_ORG_TOKEN: 'nothing'
      TRAVIS_PRO_URL: 'nothing'
      TRAVIS_PRO_TOKEN: 'nothing'
      QUAY_URL: QUAY_URL
      QUAY_TOKEN: 'quay-token'
      meshbluConfig
    }
    @sut.run done

  afterEach (done) ->
    @sut.close done

  afterEach (done) ->
    @quay.close done

  afterEach (done) ->
    @etcdMajor.close done

  afterEach (done) ->
    @etcdMinor.close done

  afterEach (done) ->
    @governatorSwarm.close done

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

    @majorHandler = @governatorMajor
      .get '/status'
      .set 'Authorization', "Basic #{guvAuth}"
      .reply 200, {
        'governator:/foo/bar:quay.io/foo/bar:v1.0.0':
          key: 'governator:/foo/bar:quay.io/foo/bar:v1.0.0'
          deployAt: 2005059595
          status: 'pending'
        'governator:/baz/awefaw:quay.io/foo/bar:v1.0.0':
          key: 'governator:/baz/awefaw:quay.io/foo/bar:v1.0.0'
          deployAt: 2005059595
          status: 'pending'
      }

    statusNode =
      node:
        key: '/foo/bar/status'
        dir: true
        nodes: [
          key: '/foo/bar/status/travis'
          value: 'build successful: v1.0.0'
        ]

    majorVersionNode =
      node:
        key: '/foo/bar/docker_url'
        dir: true
        nodes: [
          key: '/foo/bar/docker_url'
          value: 'quay.io/foo/bar:v0.9.9'
        ]

    minorVersionNode =
      node:
        key: '/foo/bar/docker_url'
        dir: true
        nodes: [
          key: '/foo/bar/docker_url'
          value: 'quay.io/foo/bar:v1.0.0'
        ]

    vulcandNode =
      node:
        key: '/vulcand/backends/foo-bar/servers'
        dir: true
        nodes: [
          key: '/vulcand/backends/foo-bar/servers'
          value: '{"Id":"octoblu-foo-bar-development-1","URL":"http://172.17.8.101:32771"}'
        ]

    @etcdMajorStatusHandler = @etcdMajor
      .get '/v2/keys/foo/bar/status'
      .reply 200, statusNode

    @etcdMajorVulcandHandler = @etcdMajor
      .get '/v2/keys/vulcand/backends/foo-bar/servers'
      .reply 200, vulcandNode

    @etcdMajorDockerUrlHandler = @etcdMajor
      .get '/v2/keys/foo/bar/docker_url'
      .reply 200, majorVersionNode

    @etcdMinorDockerUrlHandler = @etcdMinor
      .get '/v2/keys/foo/bar/docker_url'
      .reply 200, minorVersionNode

    @quayHandler = @quay
      .get '/api/v1/repository/foo/bar/build/'
      .set 'Authorization', 'Bearer quay-token'
      .reply 200, builds: [{tags: ['v1.0.0'], phase: 'building', started: 'blah blah'}]

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
      majorVersion: 'quay.io/foo/bar:v0.9.9'
      minorVersion: 'quay.io/foo/bar:v1.0.0'
      status:
        travis: 'build successful: v1.0.0'
      deployments:
        "governator:/foo/bar:quay.io/foo/bar:v1.0.0":
          deployAt: 2005059595
          key: "governator:/foo/bar:quay.io/foo/bar:v1.0.0"
          status: "pending"
      servers:
        'octoblu-foo-bar-development-1': 'http://172.17.8.101:32771'
      quay:
        tag: 'v1.0.0'
        phase: 'building'
        startedAt: 'blah blah'

    expect(JSON.parse @response.body).to.deep.equal expectedResponse

  it 'should call the handlers', ->
    expect(@meshbluHandler.isDone).to.be.true
    expect(@etcdMajorStatusHandler.isDone).to.be.true
    expect(@etcdMajorVulcandHandler.isDone).to.be.true
    expect(@etcdMajorDockerUrlHandler.isDone).to.be.true
    expect(@etcdMinorDockerUrlHandler.isDone).to.be.true
    expect(@majorHandler.isDone).to.be.true
    expect(@quayHandler.isDone).to.be.true
