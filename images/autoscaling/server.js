var http = require('http');
var os = require('os');

var totalrequests = 0;

http.createServer(function(request, response) {
  totalrequests += 1

  response.writeHead(200);

  if (request.url == "/metrics") {
    response.end("# HELP http_requests_total The amount of requests served by the server in total\n# TYPE http_requests_total counter\nhttp_requests_total " + totalrequests + "\n");
    return;
  }
  response.end("Hello! My name is " + os.hostname() + ". I have served "+ totalrequests + " requests so far.\n");
}).listen(8080)
