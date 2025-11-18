// Import required Node.js modules
var http = require('http'); // HTTP server functionality
var os = require('os');     // Operating system utilities for hostname, etc.

/**
 * Structured logging function that outputs JSON formatted logs
 * @param {string} level - Log level (INFO, ERROR, DEBUG, etc.)
 * @param {string} message - Human readable log message
 * @param {object} metadata - Additional data to include in the log entry
 */
function log(level, message, metadata = {}) {
  const timestamp = new Date().toISOString(); // ISO 8601 timestamp for consistency

  // Create structured log entry with standard fields
  const logEntry = {
    timestamp,
    level,
    message,
    hostname: os.hostname(), // Server hostname for identification
    pid: process.pid,        // Process ID for debugging multi-instance scenarios
    ...metadata              // Spread operator to merge additional metadata
  };

  // Output as JSON string to stdout for log collectors
  console.log(JSON.stringify(logEntry));
}

/**
 * HTTP request handler function that processes all incoming requests
 * @param {object} request - HTTP request object
 * @param {object} response - HTTP response object
 */
var handleRequest = function(request, response) {
  // Generate unique request ID for tracing individual requests through logs
  const requestId = Date.now() + '-' + Math.random().toString(36).substring(2, 11);

  // Get client IP address (use socket.remoteAddress instead of deprecated connection.remoteAddress)
  let remoteAddress = request.socket.remoteAddress || 'unknown';

  // Extract IPv4 address from IPv6-mapped format (::ffff:x.x.x.x)
  if (remoteAddress.startsWith('::ffff:')) {
    remoteAddress = remoteAddress.substring(7); // Remove '::ffff:' prefix
  }

  // Log incoming request with structured metadata for monitoring/debugging
  log('INFO', 'Incoming HTTP request', {
    requestId,
    method: request.method,                    // HTTP method (GET, POST, etc.)
    url: request.url,                         // Requested URL path
    userAgent: request.headers['user-agent'] || 'unknown', // Client browser/app info
    remoteAddress,                            // Client IP address
    // Log all request headers for debugging
    headers: request.headers
  });

  // Track request processing time for performance monitoring
  const startTime = Date.now();

  try {
    // Set HTTP 200 OK status code
    response.writeHead(200, { 'Content-Type': 'text/plain' });

    // Write response body with server information
    response.write('Hostname: ' + os.hostname() + '\n');
    response.write('Timestamp: ' + new Date().getTime() + '\n');
    response.write('Request ID: ' + requestId + '\n'); // Include request ID in response

    // Include Kubernetes node name if available (set via downward API)
    if (typeof process.env.KUBERNETES_NODE_NAME !== 'undefined') {
      response.write('Kubernetes node name: ' + process.env.KUBERNETES_NODE_NAME + '\n');
    }

    // Include client IP address in response
    response.write('\n');
    response.write('Client IP: ' + remoteAddress + '\n');

    // Write full request headers to response body
    response.write('\n');
    response.write('Request Headers:\n');
    for (const [headerName, headerValue] of Object.entries(request.headers)) {
      response.write(headerName + ': ' + headerValue + '\n');
    }

    // End the HTTP response
    response.end();

    // Log request completion with performance metrics
    const duration = Date.now() - startTime;
    log('INFO', 'Request completed', {
      requestId,
      duration,      // Processing time in milliseconds
      statusCode: 200
    });

  } catch (error) {
    // Log any errors during request processing
    log('ERROR', 'Error processing request', {
      requestId,
      error: error.message,
      stack: error.stack
    });

    // Send error response if headers haven't been sent
    if (!response.headersSent) {
      response.writeHead(500);
      response.end('Internal Server Error');
    }
  }
};

// Create HTTP server instance with our request handler
var www = http.createServer(handleRequest);

// Add error handler for server
www.on('error', (error) => {
  log('ERROR', 'Server error', {
    error: error.message,
    code: error.code
  });
});

// Log server startup with configuration details
log('INFO', 'Starting HTTP server', {
  port: 8080,
  nodeVersion: process.version,                               // Node.js version
  kubernetesNode: process.env.KUBERNETES_NODE_NAME || 'not-set' // K8s node or fallback
});

// Start the server listening on port 8080
www.listen(8080, () => {
  // Log when server is ready to accept connections
  log('INFO', 'HTTP server listening', { port: 8080 });
});

// Disable HTTP keep-alive to force connection closure after each request
www.keepAliveTimeout = 0;

// Handle SIGTERM signal (sent by Kubernetes during pod termination)
process.on('SIGTERM', () => {
  log('INFO', 'Received SIGTERM, shutting down gracefully');
  www.close(() => {
    log('INFO', 'Server closed');
    process.exit(0); // Clean exit
  });
});

// Handle SIGINT signal (Ctrl+C during development)
process.on('SIGINT', () => {
  log('INFO', 'Received SIGINT, shutting down gracefully');
  www.close(() => {
    log('INFO', 'Server closed');
    process.exit(0); // Clean exit
  });
});