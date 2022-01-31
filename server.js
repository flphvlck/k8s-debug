var http = require('http');

var handleRequest = function(request, response) {
  console.log('Received request for URL: ' + request.url);
  console.log('Headers: ' + JSON.stringify(request.headers));
  response.writeHead(200);
  response.write('Hostname: ' + require('os').hostname() + '\n' + 'Timestamp: ' + new Date().getTime() + '\n');
  if (typeof process.env.KUBERNETES_NODE_NAME !== 'undefined') {
    response.write(process.env.KUBERNETES_NODE_NAME + '\n');
  };
  response.end();
};
var www = http.createServer(handleRequest);
www.listen(8080);
