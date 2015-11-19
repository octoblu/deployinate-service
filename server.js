require('coffee-script/register');
var Server = require('./src/server.coffee');

var port = process.env.PORT || 80;

server = new Server({port: port});

server.run(function(error){
  if (error) {
    console.error(error.stack);
    process.exit(1);
  }
  var host = server.address().address;
  var port = server.address().port;
  console.log('Server running on ' + host + ':' + port);
});
