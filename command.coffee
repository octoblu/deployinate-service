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
    ETCD_MAJOR_URI = process.env.ETCD_MAJOR_URI
    ETCD_MINOR_URI = process.env.ETCD_MINOR_URI
    TRAVIS_PRO_URL = 'https://api.travis-ci.com'
    TRAVIS_ORG_URL = 'https://api.travis-ci.org'
    TRAVIS_PRO_TOKEN = process.env.TRAVIS_PRO_TOKEN
    TRAVIS_ORG_TOKEN = process.env.TRAVIS_ORG_TOKEN
    GOVERNATOR_MAJOR_URL = process.env.GOVERNATOR_MAJOR_URL
    GOVERNATOR_MINOR_URL = process.env.GOVERNATOR_MINOR_URL
    GOVERNATOR_SWARM_URL = process.env.GOVERNATOR_SWARM_URL
    QUAY_URL = process.env.QUAY_URL
    QUAY_TOKEN = process.env.QUAY_TOKEN
    meshbluConfig = new MeshbluConfig().toJSON()

    @panic new Error('env variable ETCD_MAJOR_URI is required') unless ETCD_MAJOR_URI?
    @panic new Error('env variable ETCD_MINOR_URI is required') unless ETCD_MINOR_URI?
    @panic new Error('env variable GOVERNATOR_MAJOR_URL is required') unless GOVERNATOR_MAJOR_URL?
    @panic new Error('env variable GOVERNATOR_MINOR_URL is required') unless GOVERNATOR_MINOR_URL?
    @panic new Error('env variable GOVERNATOR_SWARM_URL is required') unless GOVERNATOR_SWARM_URL?
    @panic new Error('env variable QUAY_URL is required') unless QUAY_URL?
    @panic new Error('env variable QUAY_TOKEN is required') unless QUAY_TOKEN?
    @panic new Error('env variable TRAVIS_PRO_URL is required') unless TRAVIS_PRO_URL?
    @panic new Error('env variable TRAVIS_ORG_URL is required') unless TRAVIS_ORG_URL?
    @panic new Error('env variable TRAVIS_PRO_TOKEN is required') unless TRAVIS_PRO_TOKEN?
    @panic new Error('env variable TRAVIS_ORG_TOKEN is required') unless TRAVIS_ORG_TOKEN?
    @panic new Error('UUID must be provided from MeshbluConfig') unless meshbluConfig?.uuid?

    server = new Server {
      port
      ETCD_MAJOR_URI
      ETCD_MINOR_URI
      GOVERNATOR_MAJOR_URL
      GOVERNATOR_MINOR_URL
      GOVERNATOR_SWARM_URL
      TRAVIS_ORG_URL
      TRAVIS_ORG_TOKEN
      TRAVIS_PRO_URL
      TRAVIS_PRO_TOKEN
      QUAY_URL
      QUAY_TOKEN
      meshbluConfig
    }

    server.run (error) =>
      @panic error if error?

      {address, port} = server.address()
      console.log "Server running on #{address}:#{port}"

    process.on 'SIGTERM', =>
      console.log 'SIGTERM caught, exiting'
      server.stop =>
        process.exit 0

      setTimeout =>
        console.log 'Server did not stop in time, exiting 0 manually'
        process.exit 0
      , 5000

command = new Command()
command.run()
