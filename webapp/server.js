const http = require('http');

const port = process.env.PORT || 3000;
const serverName = process.env.SERVER_NAME || 'unknown';
const region = process.env.REGION || 'unknown';

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(`<!DOCTYPE html>
<html>
<head>
  <title>poms.tech</title>
  <style>
    body { font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: #1a1a2e; color: #e0e0e0; }
    .container { text-align: center; padding: 40px; background: #16213e; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.3); }
    h1 { color: #00d4ff; font-size: 2.5em; margin-bottom: 10px; }
    .info { font-size: 1.3em; margin: 15px 0; }
    .label { color: #888; }
    .value { color: #00d4ff; font-weight: bold; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Welcome to poms.tech</h1>
    <div class="info"><span class="label">Server:</span> <span class="value">${serverName}</span></div>
    <div class="info"><span class="label">Region:</span> <span class="value">${region}</span></div>
  </div>
</body>
</html>`);
});

server.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
