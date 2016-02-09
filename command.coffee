colors        = require 'colors'
MeshbluConfig = require 'meshblu-config'
Server        = require './src/server.coffee'

class Command
  panic: (error) =>
    console.error colors.red error.message
    console.error error.stack
    process.exit 1

  run: =>
    port = process.env.PORT || 80
    ETCDCTL_PEERS = process.env.ETCDCTL_PEERS ? 'http://localhost:2379'
    TRAVIS_PRO_URL = 'https://api.travis-ci.com'
    TRAVIS_ORG_URL = 'https://api.travis-ci.org'
    TRAVIS_PRO_TOKEN = process.env.TRAVIS_PRO_TOKEN
    TRAVIS_ORG_TOKEN = process.env.TRAVIS_ORG_TOKEN
    GOVERNATOR_MINOR_URL = process.env.GOVERNATOR_MINOR_URL
    meshbluConfig = new MeshbluConfig().toJSON()

    @panic new Error('env variable ETCDCTL_PEERS is required') unless ETCDCTL_PEERS?
    @panic new Error('env variable GOVERNATOR_MINOR_URL is required') unless GOVERNATOR_MINOR_URL?
    @panic new Error('env variable TRAVIS_PRO_URL is required') unless TRAVIS_PRO_URL?
    @panic new Error('env variable TRAVIS_ORG_URL is required') unless TRAVIS_ORG_URL?
    @panic new Error('env variable TRAVIS_PRO_TOKEN is required') unless TRAVIS_PRO_TOKEN?
    @panic new Error('env variable TRAVIS_ORG_TOKEN is required') unless TRAVIS_ORG_TOKEN?
    @panic new Error('UUID must be provided from MeshbluConfig') unless meshbluConfig?.uuid?

    server = new Server {
      port
      ETCDCTL_PEERS
      GOVERNATOR_MINOR_URL
      TRAVIS_ORG_URL
      TRAVIS_ORG_TOKEN
      TRAVIS_PRO_URL
      TRAVIS_PRO_TOKEN
      meshbluConfig
    }

    server.run (error) =>
      @panic error if error?

      {address, port} = server.address()
      console.log "Server running on #{address}:#{port}"

command = new Command()
command.run()
