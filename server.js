var http = require('http');

var handleRequest = function(request, response) {
  console.log('Received request for URL: ' + request.url);
  console.log('Headers: ' + JSON.stringify(request.headers));
  response.writeHead(200);
  response.write('Hostname: ' + require('os').hostname() + '\n');
  response.end();
};
var www = http.createServer(handleRequest);
www.listen(8080);