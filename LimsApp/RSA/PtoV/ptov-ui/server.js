const http = require('http');
const express = require('express');
const config = require('./config');

const app = express();

console.log('Started server.js');
config.express(app, config.app);

const server = {
  start: function start() {
    const port = 9092;
    const httpServer = http.createServer(app);
    httpServer.listen(port, '0.0.0.0');
    console.log(`Server running at http://localhost:${port}`);
  }
};
server.start();
