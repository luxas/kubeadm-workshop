var http = require('http');
var os = require('os');

var requests = [];
var totalrequests = 0;
var resolution = 5;

http.createServer(function(request, response) {
  var now = new Date().getTime();

  for (var i = 0; i < requests.length; i++) {
    if (requests[i] < now - resolution * 1000) {
      // A request that's too old is removed
      requests.splice(i, 1);
      i--
    }
  }
  requests.push(now)
  totalrequests++

  var avgQps = requests.length / resolution;

  response.writeHead(200);

  if (request.url == "/metrics") {
    response.write("# HELP http_requests_total The amount of requests served by the server in total\n# TYPE http_requests_total counter\nhttp_requests_total " + totalrequests + "\n");
    response.end("# HELP http_requests_per_second The amount of requests per second served by the server the latest five seconds\n# TYPE http_requests_per_second gauge\nhttp_requests_per_second " + avgQps + "\n");
    return;
  }
  response.end("Hello! My name is " + os.hostname() + ". The last " + resolution + " seconds, the average QPS has been " + avgQps + ". Total requests served: "+ totalrequests + "\n");
}).listen(8080)
