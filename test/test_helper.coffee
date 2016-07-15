chai       = require 'chai'
chaiSubset = require 'chai-subset'
sinon      = require 'sinon'
sinonChai  = require 'sinon-chai'

chai.use chaiSubset
chai.use sinonChai

global.expect = chai.expect
global.sinon  = sinon
