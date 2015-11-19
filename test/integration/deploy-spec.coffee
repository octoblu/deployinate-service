http = require 'http'
request = require 'request'
shmock = require 'shmock'
Server = require '../../src/server'

xdescribe 'POST /deploy', ->
  beforeEach ->
    @meshblu = shmock 0xb33f

  afterEach (done) ->
    @meshblu.close => done()

  beforeEach (done) ->
    meshbluConfig =
      server: 'localhost'
      port: 0xb33f

    @server = new Server
      port: undefined, {meshbluConfig: meshbluConfig}
    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach (done) ->
    @server.stop => done()

  beforeEach (done) ->
    auth =
      username: 'team-uuid'
      password: 'team-token'

    device =
      uuid: 'virtual-device-uuid'
      foo: 'bar'
      meshblu: 'pwned!'
      owner: 'someone-else'
      token: 'steal-me'
      sendWhitelist: []
      recieveWhitelist: []
      configureWhitelist: []
      discoverWhitelist: []
      sendBlacklist: []
      recieveBlacklist: []
      configureBlacklist: []
      discoverBlacklist: []
      sendAsWhitelist: []
      recieveAsWhitelist: []
      configureAsWhitelist: []
      discoverAsWhitelist: []

    options =
      auth: auth
      json: device

    @meshblu.get('/v2/whoami')
      .reply(200, '{"uuid": "team-uuid"}')

    @patchHandler = @meshblu.patch('/v2/devices/real-device-uuid')
      .send(foo: 'bar')
      .reply(204, http.STATUS_CODES[204])

    request.post "http://localhost:#{@serverPort}/config/real-device-uuid", options, (@error, @response, @body) =>
      done @error

  it 'should update the real device in meshblu', ->
    expect(@response.statusCode).to.equal 204
    expect(@patchHandler.isDone).to.be.true
