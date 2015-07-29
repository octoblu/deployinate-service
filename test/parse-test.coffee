Model = require './src/etcd-parser-model'
fs = require 'fs'

data = fs.readFileSync './keys.json'
m = new Model '/octoblu/app-octoblu', data

m.parse (error, data) =>
  console.log data
